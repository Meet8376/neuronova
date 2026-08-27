import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/sync_service.dart';

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
}

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
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('patients');
    final syncStats = await SyncService.instance.getSyncSummary();

    final loaded = rows.map((r) {
      return PatientProfile(
        id: r['id'] as String,
        name: r['name'] as String,
        age: r['age'] as int,
        village: r['village'] as String,
        cognitiveIndex: r['cognitive_index'] as int,
        status: r['status'] as String,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _patients = loaded;
      _syncSummary = syncStats;
      _loading = false;
    });
  }

  Future<void> _triggerSync() async {
    setState(() {
      _syncing = true;
    });
    final result = await SyncService.instance.performSync();
    if (!mounted) return;
    setState(() {
      _syncSummary = result;
      _syncing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Offline Sync Complete: ${result.totalSynced} items reconciled!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _switchPatient(String patientId) {
    setState(() {
      _activePatientId = patientId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched active patient profile to ID: $patientId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('ASHA Patient Roster & Sync', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Offline sync card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: AppColors.primary.withOpacity(0.08),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sync_rounded, color: AppColors.primary, size: 28),
                                const SizedBox(width: 10),
                                const Text(
                                  'Offline Data Sync',
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Online Ready', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pending Queue Items: ${_syncSummary?.pendingItems ?? 0}\nLast Reconciled: ${_syncSummary?.lastSyncTime ?? "N/A"}',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _syncing ? null : _triggerSync,
                                icon: _syncing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                                label: Text(
                                  _syncing ? 'Syncing...' : 'Sync Pending Sessions Now',
                                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Assigned Patients (Multi-Patient Care)',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ..._patients.map((patient) {
                      final isActive = patient.id == _activePatientId;
                      final isAlert = patient.status == 'attention_needed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isActive ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: isAlert ? Colors.orange.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                            child: Icon(
                              isAlert ? Icons.warning_rounded : Icons.person_rounded,
                              color: isAlert ? Colors.orange : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            patient.name,
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Age: ${patient.age} • ${patient.village}\nCognitive Index: ${patient.cognitiveIndex}%',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? AppColors.primary : Colors.grey[200],
                              foregroundColor: isActive ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _switchPatient(patient.id),
                            child: Text(isActive ? 'Active' : 'Select'),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
