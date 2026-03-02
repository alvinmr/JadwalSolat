import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    /// Prayers currently held for scheduling (today + tomorrow)
    private var cachedPrayers: [PrayerTime] = []

    /// Whether we have confirmed notification authorisation
    private var isAuthorised = false

    /// Request permission. Once granted, automatically schedules any cached prayers.
    func requestPermission() {
        let bundleId = Bundle.main.bundleIdentifier
        diskLog("requestPermission called. Bundle ID: \(bundleId ?? "nil")")

        if bundleId == nil {
            diskLog("⚠️  No bundle identifier — notifications will NOT work. Build as .app bundle with: bash scripts/build-app.sh")
            return
        }

        attemptAuthorisation(retriesLeft: 3, delay: 5)
    }

    /// Retry-capable authorisation. macOS may reject the first call for a new app
    /// because it needs to register the app in Notification Center first.
    private func attemptAuthorisation(retriesLeft: Int, delay: TimeInterval) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            diskLog("Auth check (retries left: \(retriesLeft)): status=\(settings.authorizationStatus.rawValue)")

            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                diskLog("Already authorised — scheduling cached prayers")
                self.isAuthorised = true
                self.applySchedule()
                return
            }

            if settings.authorizationStatus == .denied && retriesLeft <= 0 {
                diskLog("⚠️  Notifications DENIED by user. Go to System Settings → Notifications → Jadwal Solat → Allow Notifications")
                return
            }

            // Request authorisation
            diskLog("Requesting notification authorisation...")
            center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
                guard let self else { return }
                diskLog("Permission result: granted=\(granted), error=\(String(describing: error))")

                if granted {
                    self.isAuthorised = true
                    self.applySchedule()
                } else if retriesLeft > 0 {
                    // macOS sometimes rejects the first request for a new app but registers it.
                    // Retry after a delay when the system may have updated its state.
                    diskLog("Will retry authorisation in \(delay)s (\(retriesLeft - 1) retries left)")
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.attemptAuthorisation(retriesLeft: retriesLeft - 1, delay: delay)
                    }
                } else {
                    diskLog("⚠️  All retries exhausted. Enable notifications in System Settings → Notifications → Jadwal Solat")
                }
            }
        }
    }

    /// Call this whenever prayer times are refreshed.
    /// Pass **both** today's and tomorrow's prayers so there is always something to schedule.
    func scheduleNotifications(for prayers: [PrayerTime]) {
        cachedPrayers = prayers
        applySchedule()
    }

    /// Re-apply the schedule using the cached prayers (e.g. after toggling a bell).
    func reschedule() {
        applySchedule()
    }

    /// Fire a test notification after 3 seconds to verify the system is working.
    func sendTestNotification() {
        let center = UNUserNotificationCenter.current()

        // Try to request permission first if not yet authorised
        if !isAuthorised {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
                guard let self else { return }
                diskLog("Test: re-requested permission — granted: \(granted), error: \(String(describing: error))")
                if granted {
                    self.isAuthorised = true
                    self.fireTestNotification()
                    // Also schedule the real prayer notifications now that we have permission
                    self.applySchedule()
                } else {
                    diskLog("⚠️  Cannot send test notification — permission not granted")
                }
            }
            return
        }

        fireTestNotification()
    }

    // MARK: - Private

    private func fireTestNotification() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Uji Notifikasi"
        content.body = "Notifikasi Jadwal Solat berfungsi dengan baik \u{2705}"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                diskLog("Test notification failed: \(error)")
            } else {
                diskLog("Test notification scheduled — fires in 3s")
            }
        }
    }

    private func applySchedule() {
        guard !cachedPrayers.isEmpty else {
            diskLog("applySchedule: no cached prayers yet")
            return
        }

        let center = UNUserNotificationCenter.current()

        // Check authorisation first so we can log clearly when it is missing
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            diskLog("Notification auth status: \(settings.authorizationStatus.rawValue)")

            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                diskLog("Notifications not authorised — skipping schedule. (Run as .app bundle and allow notifications in System Settings)")
                return
            }

            self.isAuthorised = true
            center.removeAllPendingNotificationRequests()

            var scheduledCount = 0
            for prayer in self.cachedPrayers {
                guard NotificationPreferences.shared.isEnabled(prayer.name) else {
                    diskLog("Skipped \(prayer.name.displayName) — disabled by user")
                    continue
                }

                // Only schedule future notifications; skip any time that has already passed
                let interval = prayer.time.timeIntervalSinceNow
                guard interval > 1 else {
                    diskLog("Skipped \(prayer.name.displayName) — already past (\(prayer.timeString))")
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Waktu \(prayer.name.displayName)"
                content.body = "Sudah masuk waktu \(prayer.name.displayName) (\(prayer.timeString))"
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

                let request = UNNotificationRequest(
                    identifier: "prayer-\(prayer.name.rawValue)-\(prayer.timeString)",
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error {
                        diskLog("Failed to add notification for \(prayer.name.displayName): \(error)")
                    }
                }
                scheduledCount += 1
                diskLog("Scheduled \(prayer.name.displayName) at \(prayer.timeString) — fires in \(Int(interval))s")
            }

            diskLog("Total notifications scheduled: \(scheduledCount)")

            // Debug: list pending notifications
            center.getPendingNotificationRequests { requests in
                diskLog("Pending notification requests: \(requests.count)")
                for r in requests {
                    diskLog("  • \(r.identifier) trigger: \(String(describing: r.trigger))")
                }
            }
        }
    }
}
