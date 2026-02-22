import Foundation

enum PrayerName: String, CaseIterable, Codable {
    case imsak, subuh, dzuhur, ashar, maghrib, isya

    var displayName: String {
        switch self {
        case .imsak: return "Imsak"
        case .subuh: return "Subuh"
        case .dzuhur: return "Dzuhur"
        case .ashar: return "Ashar"
        case .maghrib: return "Maghrib"
        case .isya: return "Isya"
        }
    }
}

struct PrayerTime {
    let name: PrayerName
    let time: Date

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    static func nextPrayer(from prayers: [PrayerTime], after date: Date) -> PrayerTime? {
        return prayers.first { $0.time > date }
    }

    /// Returns the current active prayer (the most recent prayer that has already started)
    static func currentPrayer(from prayers: [PrayerTime], at date: Date) -> PrayerTime? {
        return prayers.last { $0.time <= date }
    }

    func countdownString(from now: Date) -> String {
        let interval = time.timeIntervalSince(now)
        guard interval > 0 else { return "" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)j \(minutes)m"
        }
        return "\(minutes)m"
    }
}
