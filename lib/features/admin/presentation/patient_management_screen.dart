import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/sync_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String village;
  final int cognitiveIndex;
  final String status;

  const PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.village,
    required this.cognitiveIndex,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case 'attention_needed': return AppColors.error;
      case 'stable':           return AppColors.success;
      default:                 return AppColors.textHint;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'attention_needed': return 'Needs Attention';
      case 'stable':           return 'Stable';
      default:                 return status;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  List<PatientProfile> _patients = [];
  String _activePatientId = 'p1';
  SyncStatusSummary? _syncSummary;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db       = await DatabaseHelper.instance.database;
    final rows     = await db.query('patients');
    final syncStats = await SyncService.instance.getSyncSummary();

    final loaded = rows.map((r) => PatientProfile(
      id:             r['id'] as String,
      name:           r['name'] as String,
      age:            r['age'] as int,
      village:        r['village'] as String,
      cognitiveIndex: r['cognitive_index'] as int,
      status:         r['status'] as String,
    )).toList();

    if (!mounted) return;
    setState(() {
      _patients    = loaded;
      _syncSummary = syncStats;
      _loading     = false;
    });
  }

  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    final result = await SyncService.instance.performSync();
    if (!mounted) return;
    setState(() {
      _syncSummary = result;
      _syncing     = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync complete — ${result.totalSynced} items updated'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _switchPatient(String id) {
    setState(() => _activePatientId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Active patient profile switched'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddPatient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPatientSheet(onAdded: _loadData),
    );
  }

  // ── Computed stats ─────────────────────────────────────────────────────────

  int get _alertCount =>
      _patients.where((p) => p.status == 'attention_needed').length;

  double get _avgCognition {
    if (_patients.isEmpty) return 0;
    return _patients
            .map((p) => p.cognitiveIndex)
            .reduce((a, b) => a + b) /
        _patients.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Gradient header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Patient Group',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Add patient button
                        GestureDetector(
                          onTap: _showAddPatient,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 5),
                                Text('Add', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Group stats row
                    if (!_loading)
                      Row(
                        children: [
                          _StatPill(label: 'Patients', value: '${_patients.length}', icon: Icons.people_outline),
                          const SizedBox(width: 10),
                          _StatPill(label: 'Alerts', value: '$_alertCount', icon: Icons.warning_amber_rounded, highlight: _alertCount > 0),
                          const SizedBox(width: 10),
                          _StatPill(label: 'Avg Score', value: '${_avgCognition.round()}%', icon: Icons.psychology_rounded),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Sync card
                        _SyncCard(
                          syncSummary: _syncSummary,
                          syncing: _syncing,
                          onSync: _triggerSync,
                        ),
                        const SizedBox(height: 20),

                        // Patient list header
                        Row(
                          children: [
                            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 10),
                            Text('Assigned Patients', style: AppTextStyles.sectionHeader(context)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_patients.isEmpty)
                          _buildEmptyPatients()
                        else
                          ..._patients.map((p) => _PatientCard(
                                patient: p,
                                isActive: p.id == _activePatientId,
                                onSelect: () => _switchPatient(p.id),
                              )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No patients assigned yet', style: AppTextStyles.sectionHeader(context).copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text("Tap 'Add' to add your first patient", style: AppTextStyles.label(context)),
          ],
        ),
      ),
    );
  }
}

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatPill({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: highlight ? AppColors.error.withOpacity(0.15) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlight ? AppColors.error.withOpacity(0.4) : Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: highlight ? AppColors.emergencyLight : Colors.white, size: 18),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Colors.white.withOpacity(0.78))),
          ],
        ),
      ),
    );
  }
}

// ─── Sync card ────────────────────────────────────────────────────────────────

class _SyncCard extends StatelessWidget {
  final SyncStatusSummary? syncSummary;
  final bool syncing;
  final VoidCallback onSync;

  const _SyncCard({required this.syncSummary, required this.syncing, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Offline Data Sync', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('Online', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pending: ${syncSummary?.pendingItems ?? 0} items\nLast sync: ${syncSummary?.lastSyncTime ?? "Never"}',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
              label: Text(syncing ? 'Syncing…' : 'Sync Now',
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Patient card ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final PatientProfile patient;
  final bool isActive;
  final VoidCallback onSelect;

  const _PatientCard({required this.patient, required this.isActive, required this.onSelect});

  Color get _avatarColor {
    final colors = [
      const Color(0xFF2A7B6F),
      const Color(0xFF5C6BC0),
      const Color(0xFFE8A020),
      const Color(0xFF2E7D5A),
      const Color(0xFF8E3B46),
    ];
    return colors[patient.name.codeUnits[0] % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: isActive ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: AppColors.divider, width: 1),
        boxShadow: isActive ? AppShadows.card : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  patient.name[0].toUpperCase(),
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800, color: _avatarColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(patient.name,
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Active', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Age ${patient.age} · ${patient.village}',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Cognitive score bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: patient.cognitiveIndex / 100,
                            backgroundColor: AppColors.divider,
                            color: patient.cognitiveIndex > 60 ? AppColors.success : AppColors.warning,
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${patient.cognitiveIndex}%',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: patient.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(patient.statusLabel,
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600, color: patient.statusColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Select button
            if (!isActive)
              GestureDetector(
                onTap: onSelect,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Text('Select',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Patient Bottom Sheet ─────────────────────────────────────────────────

class _AddPatientSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddPatientSheet({required this.onAdded});

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController();
  final _villageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    // Also register them as a DB user so they can log in
    final username = _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '.');
    await UserRepository().registerUser(
      username: username,
      displayName: _nameCtrl.text.trim(),
      password: 'care1234', // default password — caregiver should tell them
      role: 'patient',
    );

    // Insert into patients table
    final db = await DatabaseHelper.instance.database;
    await db.insert('patients', {
      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
      'village': _villageCtrl.text.trim(),
      'status': 'stable',
      'cognitive_index': 75,
      'last_active': DateTime.now().millisecondsSinceEpoch,
      'missed_meds': 0,
    });

    if (!mounted) return;
    Navigator.pop(context);
    widget.onAdded();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient added! Login: $username / care1234'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          ),
          const Text('Add Patient',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('A login account will be created automatically.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _SheetField(controller: _nameCtrl, label: 'Full Name', hint: 'e.g. Rajan Kumar',
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null),
                const SizedBox(height: 12),
                _SheetField(controller: _ageCtrl, label: 'Age', hint: 'e.g. 72',
                    keyboardType: TextInputType.number,
                    validator: (v) { final n = int.tryParse(v ?? ''); return (n == null || n < 1) ? 'Enter valid age' : null; }),
                const SizedBox(height: 12),
                _SheetField(controller: _villageCtrl, label: 'Village / Area', hint: 'e.g. Barabanki'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Add to Group', style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
