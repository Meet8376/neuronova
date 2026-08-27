# Product Requirements Document (PRD)

## AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in North Eastern Region (NER)

**PS Number:** SIH26003
**Sponsoring Ministry:** Ministry of Development of North Eastern Region (MDoNER)
**Category:** Software
**Document Version:** 1.0
**Status:** Draft for SIH 2026 Submission

---

## 1. Executive Summary

The North Eastern Region (NER) of India faces a growing burden of age-related cognitive disorders such as dementia, compounded by limited access to specialized neurological care due to geographic isolation and thin healthcare infrastructure. This PRD defines an AI-enabled, offline-capable, multilingual cognitive gaming and memory assistance platform designed for elderly dementia patients in NER, with integrated caregiver monitoring, adaptive difficulty, and culturally localized content.

The platform's mission: **enable early cognitive intervention, sustained cognitive engagement, and remote caregiver visibility, for elderly users in low-connectivity, multilingual, and low-digital-literacy environments.**

---

## 2. Problem Statement

Elderly individuals with dementia in NER experience:
- Progressive memory decline, confusion, anxiety, and social isolation
- Limited access to cognitive therapy and neurological specialists due to distance and infrastructure gaps
- Lack of affordable, culturally relevant digital therapeutic tools in regional languages

Caregivers and healthcare workers face:
- No continuous, objective way to monitor cognitive trends between clinical visits
- High burden of manual reminders (medicine, hydration, appointments)
- No early-warning mechanism for sudden cognitive/behavioral decline

There is currently no affordable, offline-capable, regionally localized digital solution addressing this gap in NER.

---

## 3. Goals & Objectives

| Goal | Description |
|---|---|
| G1 | Provide engaging, adaptive cognitive games targeting memory, attention, routine recall, and pattern recognition |
| G2 | Personalize difficulty using AI/ML based on real-time patient performance |
| G3 | Support multilingual, voice-first interaction for low-literacy elderly users |
| G4 | Deliver culturally familiar visuals, audio, and themes specific to NER communities |
| G5 | Provide reliable reminders for medicine, hydration, activities, and appointments |
| G6 | Give caregivers/health workers a dashboard to track trends and receive alerts |
| G7 | Function fully offline with sync-when-available connectivity |
| G8 | Ensure a simple, accessible, low-friction UI suitable for cognitively impaired elderly users |
| G9 | Protect sensitive patient health data with strong security and privacy controls |

---

## 4. Target Users & Personas

### Persona 1: Elderly Patient (Primary User) — "Amma/Aita/Grandmother figure"
- Age 60–85, mild-to-moderate dementia
- Low/variable digital literacy, may not read fluently even in native script
- Lives in a rural/semi-urban NER town or village
- Needs: simple navigation, familiar visuals/sounds, voice guidance, gentle reminders

### Persona 2: Family Caregiver
- Adult child or spouse, may live with patient or nearby
- Manages daily routines, medicines, and appointments
- Needs: visibility into patient's cognitive trend, alerts for concerning changes, low-effort reminder setup

### Persona 3: Community Health Worker (e.g., ASHA worker / local clinic staff)
- Manages multiple patients across a rural catchment area
- Needs: multi-patient dashboard, prioritized alerts, low-bandwidth access

---

## 5. Scope

### In Scope (v1 / Hackathon MVP)
- Cognitive game engine (4 core game types)
- Rule-based + lightweight ML adaptive difficulty
- Voice-assisted interaction (offline STT/TTS) in at least 1–2 NER regional languages
- Reminder system (medicine, hydration, activity, appointment)
- Caregiver dashboard with performance trends and alerts
- Offline-first data storage with background sync
- Secure authentication and encrypted patient data storage
- Elderly-accessible UI (large fonts, icon-first navigation, high contrast)

### Out of Scope (v1)
- Clinical diagnosis of dementia or dementia staging (explicitly a monitoring/engagement aid, not a medical diagnostic device)
- Integration with hospital EMR/EHR systems
- Full support for all NER languages (v1 covers a representative subset; architecture must allow easy addition of more)
- Video-based teleconsultation with doctors
- Wearable device integration (future roadmap item)

---

## 6. Functional Requirements

### 6.1 Cognitive Gaming Engine
| ID | Requirement |
|---|---|
| FR-1.1 | System shall provide a Memory game (e.g., match-the-pairs) using culturally familiar imagery |
| FR-1.2 | System shall provide an Attention/Concentration game (e.g., sustained visual tracking or spot-the-difference) |
| FR-1.3 | System shall provide a Daily Routine Recall game (sequencing everyday activities) |
| FR-1.4 | System shall provide a Pattern/Object Recognition game with progressively complex stimuli |
| FR-1.5 | Each game session shall log accuracy, response time, completion status, and level reached |
| FR-1.6 | Games shall include emotionally engaging elements (music, familiar visuals, positive reinforcement feedback) |

### 6.2 Adaptive Difficulty Engine
| ID | Requirement |
|---|---|
| FR-2.1 | System shall adjust game difficulty based on rolling performance (accuracy, response time) over recent sessions |
| FR-2.2 | System shall use an on-device ML model to compute a cognitive engagement/trend score from gameplay metrics |
| FR-2.3 | System shall flag significant negative shifts in performance trend to the caregiver dashboard |
| FR-2.4 | Adaptive logic shall function fully offline (on-device inference) |

### 6.3 Multilingual & Voice Interaction
| ID | Requirement |
|---|---|
| FR-3.1 | System shall support at least 2 regional NER languages for UI text and voice (configurable/extensible) |
| FR-3.2 | System shall provide offline voice instructions (TTS) for game guidance |
| FR-3.3 | System shall accept basic voice commands (offline STT) for navigation and game responses |
| FR-3.4 | System shall support culturally themed asset packs (visuals, sounds) per region, swappable via configuration |

### 6.4 Reminder System
| ID | Requirement |
|---|---|
| FR-4.1 | System shall allow caregivers to schedule medicine reminders with recurrence rules |
| FR-4.2 | System shall provide hydration and daily activity reminders |
| FR-4.3 | System shall provide appointment reminders |
| FR-4.4 | Reminders shall trigger via combined audio + visual + (optional) voice cues |
| FR-4.5 | Reminder scheduling shall work fully offline; sync to server when connectivity resumes |

### 6.5 Caregiver / Health Worker Dashboard
| ID | Requirement |
|---|---|
| FR-5.1 | Dashboard shall display cognitive performance trends over time (daily/weekly/monthly) |
| FR-5.2 | Dashboard shall display engagement metrics (session frequency, duration, completion rates) |
| FR-5.3 | Dashboard shall generate alerts for missed reminders or significant performance decline |
| FR-5.4 | System shall support role-based views: family caregiver (single patient) vs. health worker (multi-patient) |
| FR-5.5 | Dashboard shall be accessible via low-bandwidth web view in addition to mobile app |

### 6.6 Offline & Sync
| ID | Requirement |
|---|---|
| FR-6.1 | All core patient-facing functionality (games, reminders, voice) shall work without internet connectivity |
| FR-6.2 | System shall queue data locally and sync to backend when connectivity is available |
| FR-6.3 | System shall handle sync conflicts gracefully (e.g., last-write-wins with timestamp, or merge for additive data like game logs) |

### 6.7 Security & Data Privacy
| ID | Requirement |
|---|---|
| FR-7.1 | Patient health data shall be encrypted at rest and in transit |
| FR-7.2 | System shall implement role-based access control (patient/family/health worker) |
| FR-7.3 | System shall obtain and record informed consent for data collection (from patient/family) |
| FR-7.4 | System shall support data export/deletion per patient/family request |

### 6.8 Accessibility & UI
| ID | Requirement |
|---|---|
| FR-8.1 | UI shall use large fonts, high-contrast colors, and simple icon-first navigation |
| FR-8.2 | Core patient flows shall require no more than 2 taps from home screen |
| FR-8.3 | UI shall avoid abrupt transitions/animations that may cause confusion or anxiety |

---

## 7. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Game screens should load within 2 seconds on low-end Android devices |
| Reliability | App must not crash or lose data during connectivity loss |
| Scalability | Architecture should support adding new languages/themes without core code changes |
| Compatibility | Must run on low-end Android tablets/phones (Android 8+, 2GB RAM target) |
| Usability | Must be usable by elderly users with minimal or no digital literacy, ideally with caregiver-assisted first-time setup |
| Localization | Asset/config-driven language and theme system |
| Security | Compliant with basic health-data protection best practices (encryption, access control, consent) |

---

## 8. Success Metrics

| Metric | Target (illustrative for MVP/demo) |
|---|---|
| Game completion rate | > 70% of started sessions completed |
| Adaptive engine responsiveness | Difficulty adjusts within 3 sessions of consistent performance change |
| Offline functionality | 100% of core patient features usable with zero connectivity |
| Caregiver alert latency | Alert visible on dashboard within one sync cycle after event |
| Accessibility | First-time elderly user can start a game within 2 taps, no reading required |

---

## 9. Technical Architecture (High-Level)

**Client (Patient App)**
- Flutter (cross-platform, offline-first, low-end device support)
- Local storage: SQLite/Hive for offline data persistence
- On-device ML: TensorFlow Lite for adaptive difficulty scoring
- Offline STT/TTS: Vosk (or equivalent) + regional TTS voices

**Client (Caregiver/Health Worker Dashboard)**
- Web dashboard (lightweight, low-bandwidth optimized) + mobile companion view
- Role-based authentication

**Backend**
- REST API (Node.js/Express or Django REST Framework)
- Database: PostgreSQL (structured data) 
- Sync service: handles offline queue reconciliation
- Notification service: Firebase Cloud Messaging (online) + local notifications (offline)
- Encryption at rest (DB-level) and in transit (TLS)

**Data Flow**
1. Patient plays game/interacts with app → data logged locally
2. Adaptive engine (on-device) recalculates difficulty in real time
3. On connectivity, local queue syncs to backend
4. Backend aggregates trends → caregiver dashboard queries updated data
5. Alert rules evaluated server-side (and optionally on-device for offline alerting to local caregiver device)

---

## 10. Data Model (Simplified)

- **Patient**: id, name, age, preferred_language, region_theme, consent_status
- **Caregiver/HealthWorker**: id, role, linked_patient_ids
- **GameSession**: id, patient_id, game_type, accuracy, response_time, level, timestamp, sync_status
- **CognitiveScore**: id, patient_id, computed_score, trend_direction, timestamp
- **Reminder**: id, patient_id, type (medicine/hydration/activity/appointment), schedule, status
- **Alert**: id, patient_id, type, severity, timestamp, acknowledged_status

---

## 11. User Stories (Sample)

- As an **elderly patient**, I want to play a simple memory game with familiar images and voice guidance, so that I can engage without needing to read instructions.
- As a **caregiver**, I want to set up medicine reminders once, so that my parent is reminded automatically every day without my manual intervention.
- As a **health worker**, I want to see which patients show declining performance trends, so that I can prioritize home visits.
- As a **patient**, I want the app to work even when there is no internet at home, so that I can use it daily regardless of connectivity.
- As a **caregiver**, I want to be alerted if my parent hasn't played any games or missed reminders for 2+ days, so I can check in.

---

## 12. Assumptions & Constraints

- Devices used are basic Android tablets/smartphones (no assumption of high-end hardware).
- Not all NER languages will be covered in v1; architecture must be extensible.
- The platform is a **cognitive engagement and monitoring aid**, not a certified medical diagnostic device — this must be clearly stated in-app and in all documentation to avoid regulatory and ethical overreach.
- Connectivity in target areas is intermittent; offline-first is a hard requirement, not an enhancement.

---

## 13. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Overclaiming medical/diagnostic capability | Explicitly frame as engagement/monitoring tool; avoid diagnostic language in UI and pitch |
| Low elderly adoption due to complexity | Prioritize caregiver-assisted onboarding; extreme UI simplicity |
| Sync conflicts corrupting data | Use append-only logs for game sessions (no destructive overwrites) |
| Limited regional language voice data availability | Start with fewer, well-supported languages; design for extensibility |
| Sensitive health data exposure | Encryption, RBAC, consent flows built in from v1, not retrofitted |

---

## 14. Milestones (Hackathon Timeline)

| Phase | Deliverable |
|---|---|
| Phase 1 | Data schema, 2 working games, local storage |
| Phase 2 | Reminder system + adaptive difficulty (rule-based) |
| Phase 3 | Caregiver dashboard (basic version) |
| Phase 4 | Offline sync layer |
| Phase 5 | Voice + multilingual layer (1–2 languages) |
| Phase 6 | UI/UX polish, accessibility pass, demo rehearsal |

---

## 15. Out-of-Scope / Future Roadmap
- Full coverage of all NER languages and dialects
- Wearable/IoT integration for physiological monitoring
- Teleconsultation with neurologists
- Advanced clinical-grade cognitive assessment (would require certified partnership with medical bodies)

---

*This PRD is a working document for SIH 2026 (PS SIH26003) submission and should be refined based on official portal updates, mentor feedback, and user research findings.*
