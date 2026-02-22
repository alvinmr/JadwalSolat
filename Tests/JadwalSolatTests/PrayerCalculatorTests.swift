import XCTest
@testable import JadwalSolat

final class PrayerCalculatorTests: XCTestCase {
    // Jakarta coordinates
    let latitude = -6.2088
    let longitude = 106.8456
    let timezone = 7.0 // WIB = UTC+7

    func testSubuhCalculation() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let calculator = PrayerCalculator(latitude: latitude, longitude: longitude, timezone: timezone)
        let times = calculator.calculate(for: date)

        let subuh = times.first { $0.name == .subuh }
        XCTAssertNotNil(subuh)

        let cal = Calendar.current
        let hour = cal.component(.hour, from: subuh!.time)
        let minute = cal.component(.minute, from: subuh!.time)

        XCTAssertEqual(hour, 4, "Subuh hour should be 4")
        XCTAssertTrue(minute >= 20 && minute <= 50, "Subuh minute \(minute) out of expected range 20-50")
    }

    func testMaghribCalculation() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let calculator = PrayerCalculator(latitude: latitude, longitude: longitude, timezone: timezone)
        let times = calculator.calculate(for: date)

        let maghrib = times.first { $0.name == .maghrib }
        XCTAssertNotNil(maghrib)

        let cal = Calendar.current
        let hour = cal.component(.hour, from: maghrib!.time)

        XCTAssertTrue(hour == 17 || hour == 18, "Maghrib hour should be 17 or 18, got \(hour)")
    }

    func testAllPrayerTimesReturned() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let calculator = PrayerCalculator(latitude: latitude, longitude: longitude, timezone: timezone)
        let times = calculator.calculate(for: date)

        XCTAssertEqual(times.count, 6)
        XCTAssertEqual(times[0].name, .imsak)
        XCTAssertEqual(times[1].name, .subuh)
        XCTAssertEqual(times[2].name, .dzuhur)
        XCTAssertEqual(times[3].name, .ashar)
        XCTAssertEqual(times[4].name, .maghrib)
        XCTAssertEqual(times[5].name, .isya)
    }

    func testPrayerTimesAreChronological() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 1
        let date = Calendar.current.date(from: components)!

        let calculator = PrayerCalculator(latitude: latitude, longitude: longitude, timezone: timezone)
        let times = calculator.calculate(for: date)

        for i in 0..<(times.count - 1) {
            XCTAssertTrue(times[i].time < times[i + 1].time,
                "\(times[i].name.displayName) should be before \(times[i + 1].name.displayName)")
        }
    }
}
