import Foundation

class NotificationPreferences: ObservableObject {
    static let shared = NotificationPreferences()

    @Published var enabled: [PrayerName: Bool] = [:]

    private let key = "notificationPreferences"

    init() {
        if let data = UserDefaults.standard.dictionary(forKey: key) as? [String: Bool] {
            for name in PrayerName.allCases {
                enabled[name] = data[name.rawValue] ?? (name != .imsak)
            }
        } else {
            for name in PrayerName.allCases {
                enabled[name] = name != .imsak
            }
        }
    }

    func toggle(_ name: PrayerName) {
        enabled[name]?.toggle()
        save()
    }

    func isEnabled(_ name: PrayerName) -> Bool {
        enabled[name] ?? true
    }

    private func save() {
        var data: [String: Bool] = [:]
        for (name, value) in enabled {
            data[name.rawValue] = value
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}
