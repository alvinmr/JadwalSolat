import XCTest
@testable import JadwalSolat

final class PrayerTimeTests: XCTestCase {
    func testPrayerTimeCreation() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28, hour: 4, minute: 28))!

        let prayer = PrayerTime(name: .subuh, time: date)
        XCTAssertEqual(prayer.name, .subuh)
        XCTAssertEqual(prayer.timeString, "04:28")
    }

    func testPrayerNameDisplayIndonesian() {
        XCTAssertEqual(PrayerName.imsak.displayName, "Imsak")
        XCTAssertEqual(PrayerName.subuh.displayName, "Subuh")
        XCTAssertEqual(PrayerName.dzuhur.displayName, "Dzuhur")
        XCTAssertEqual(PrayerName.ashar.displayName, "Ashar")
        XCTAssertEqual(PrayerName.maghrib.displayName, "Maghrib")
        XCTAssertEqual(PrayerName.isya.displayName, "Isya")
    }

    func testNextPrayerFromList() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 14, minute: 0))!

        let prayers = [
            PrayerTime(name: .subuh, time: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 4, minute: 28))!),
            PrayerTime(name: .dzuhur, time: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12, minute: 5))!),
            PrayerTime(name: .ashar, time: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 15, minute: 22))!),
            PrayerTime(name: .maghrib, time: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 17, minute: 58))!),
            PrayerTime(name: .isya, time: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 19, minute: 10))!),
        ]

        let next = PrayerTime.nextPrayer(from: prayers, after: now)
        XCTAssertEqual(next?.name, .ashar)
    }
}
