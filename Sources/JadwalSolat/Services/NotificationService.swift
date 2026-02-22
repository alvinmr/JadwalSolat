import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    func requestPermission() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleNotifications(for prayers: [PrayerTime]) {
        guard isAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for prayer in prayers {
            guard NotificationPreferences.shared.isEnabled(prayer.name) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Waktu \(prayer.name.displayName)"
            content.body = "Sudah masuk waktu \(prayer.name.displayName) (\(prayer.timeString))"
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: prayer.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "prayer-\(prayer.name.rawValue)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
