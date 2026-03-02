import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    /// Prayers currently held for scheduling (today + tomorrow)
    private var cachedPrayers: [PrayerTime] = []

    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            diskLog("Notification permission granted: \(granted), error: \(String(describing: error))")
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

    // MARK: - Private

    private func applySchedule() {
        let center = UNUserNotificationCenter.current()

        // Check authorisation first so we can log clearly when it is missing
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            diskLog("Notification auth status: \(settings.authorizationStatus.rawValue)")
            // 0 = notDetermined, 1 = denied, 2 = authorized, 3 = provisional

            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                diskLog("Notifications not authorised — skipping schedule")
                return
            }

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

                // Use absolute interval trigger to avoid timezone / component mismatches
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
