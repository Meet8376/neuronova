# Walkthrough — Prototype Deployment

I have successfully resolved the compilation issues and deployed the prototype of **CogniCare** onto your wirelessly connected Android device.

## What Was Fixed
* Added the missing `content_item.dart` import in [progress_screen.dart](file:///C:/Users/prana/Downloads/cognicare_prototype/lib/features/progress/presentation/progress_screen.dart) to expose the `displayName` extension getter for categories.
* Configured **Core Library Desugaring** in [build.gradle.kts](file:///C:/Users/prana/Downloads/cognicare_prototype/android/app/build.gradle.kts) to support modern Java APIs utilized by the notification engine.

## Deployment Status
* **Target Device:** `A015` (`192.168.29.64:35451`) — Android 16 (API 36).
* **Compile Status:** Successfully compiled and built debug APK (`assembleDebug`).
* **Execution Status:** Installed and running. The app has launched to the splash screen and is transitioning to the **Role Select Screen** for initial setup.

---

## How to Test on Your Phone
1. **Initial Setup (Role Select):**
   * Enter the **Patient's name** (e.g. Rajan Kumar) and the **Caregiver's name** (e.g. Priya).
   * Choose to open the app as a **Patient** or **Caregiver / Admin**.
2. **Explore the Patient Dashboard:**
   * **Tasks sub-tab:** Tap the checkmark circle to complete a task, or tap a task card to see actions (*Mark as Done*, *Starting Now*, *Remind Later*). Use the FAB to add tasks with options for *Public* vs *Private* (hidden from caregiver).
   * **Health sub-tab:** Track hydration (tap to record cups of water) and view the scheduled medicine list.
3. **Try the Cognitive Memory Game:**
   * Navigate to the **Games** tab and choose **Read, Memorize & Speak**.
   * Pick your language (English/Hindi), category (Gita, Stories, Conversations), and length.
   * **Phase 1 (Read):** Listen to the passage read aloud using text-to-speech with word-by-word yellow highlights.
   * **Phase 2 (Speak):** Tap the microphone to speak the passage from memory (uses on-device speech recognition) or type it manually.
   * **Phase 3 (Results):** See your circular score percentage (F1-score + LCS word order matching) with motivational feedback.
4. **Caregiver View:**
   * Go to **Profile** and switch to **Caregiver View**.
   * See the caregiver dashboard detailing patient progress stats, today's public tasks, medicine adherence tracker, and the score from their last cognitive session.
