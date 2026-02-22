# Jadwal Solat Menu Bar App — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that shows Ramadan prayer times with countdown, auto-location, and notifications.

**Architecture:** Swift Package Manager executable using AppKit + SwiftUI for the menu bar interface. Core prayer calculation engine uses astronomical formulas (Kemenag RI method). CoreLocation for auto-detect, UserNotifications for alerts.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSStatusBar), CoreLocation, UserNotifications, macOS 13+

---

### Task 1: Set Up Swift Package Project

**Files:**
- Create: `Package.swift`
- Create: `Sources/JadwalSolat/main.swift` (placeholder entry point)

**Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JadwalSolat",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "JadwalSolat",
            path: "Sources/JadwalSolat"
        ),
        .testTarget(
            name: "JadwalSolatTests",
            dependencies: ["JadwalSolat"],
            path: "Tests/JadwalSolatTests"
        )
    ]
)
```

**Step 2: Create placeholder main.swift**

```swift
import AppKit

let app = NSApplication.shared
app.run()
```

**Step 3: Verify it builds**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Package.swift Sources/
git commit -m "feat: initialize Swift package project"
```

---

### Task 2: Prayer Time Model

**Files:**
- Create: `Sources/JadwalSolat/Models/PrayerTime.swift`
- Create: `Tests/JadwalSolatTests/PrayerTimeTests.swift`

**Step 1: Write failing test for PrayerTime model**

```swift
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
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/user/Development/JadwalSolat && swift test --filter PrayerTimeTests`
Expected: FAIL — types not found

**Step 3: Implement PrayerTime model**

```swift
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
```

**Step 4: Run tests to verify they pass**

Run: `cd /Users/user/Development/JadwalSolat && swift test --filter PrayerTimeTests`
Expected: All 3 tests PASS

**Step 5: Commit**

```bash
git add Sources/JadwalSolat/Models/PrayerTime.swift Tests/
git commit -m "feat: add PrayerTime model with next prayer and countdown logic"
```

---

### Task 3: Prayer Calculator (Core Astronomical Math)

**Files:**
- Create: `Sources/JadwalSolat/Models/PrayerCalculator.swift`
- Create: `Tests/JadwalSolatTests/PrayerCalculatorTests.swift`

**Step 1: Write failing test**

Test against known prayer times for Jakarta on a specific date (verified against Kemenag data).

```swift
import XCTest
@testable import JadwalSolat

final class PrayerCalculatorTests: XCTestCase {
    // Jakarta coordinates
    let latitude = -6.2088
    let longitude = 106.8456
    let timezone = 7.0 // WIB = UTC+7

    func testSubuhCalculation() {
        // Test date: March 1, 2026 — expected Subuh ~04:35 WIB (approximate)
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

        // Subuh should be between 04:20 and 04:50 for Jakarta in March
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

        // Maghrib should be around 17:50-18:10 for Jakarta in March
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

        XCTAssertEqual(times.count, 6) // Imsak, Subuh, Dzuhur, Ashar, Maghrib, Isya
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
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/user/Development/JadwalSolat && swift test --filter PrayerCalculatorTests`
Expected: FAIL — PrayerCalculator not found

**Step 3: Implement PrayerCalculator**

```swift
import Foundation

struct PrayerCalculator {
    let latitude: Double
    let longitude: Double
    let timezone: Double

    // Kemenag RI angles
    private let subuhAngle = 20.0
    private let isyaAngle = 18.0

    func calculate(for date: Date) -> [PrayerTime] {
        let cal = Calendar.current
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        let year = cal.component(.year, from: date)

        let d = julianDate(year: year, dayOfYear: dayOfYear)
        let sunDecl = sunDeclination(d: d)
        let eqOfTime = equationOfTime(d: d)

        let transitTime = solarNoon(eqOfTime: eqOfTime)

        let subuhTime = transitTime - hourAngle(angle: subuhAngle, decl: sunDecl) / 15.0
        let sunriseTime = transitTime - hourAngle(angle: 0.8333, decl: sunDecl) / 15.0
        let dzuhurTime = transitTime
        let asharTime = transitTime + asharHourAngle(decl: sunDecl) / 15.0
        let maghribTime = transitTime + hourAngle(angle: 0.8333, decl: sunDecl) / 15.0
        let isyaTime = transitTime + hourAngle(angle: isyaAngle, decl: sunDecl) / 15.0
        let imsakTime = subuhTime - 10.0 / 60.0

        return [
            makePrayerTime(.imsak, hours: imsakTime, date: date),
            makePrayerTime(.subuh, hours: subuhTime, date: date),
            makePrayerTime(.dzuhur, hours: dzuhurTime, date: date),
            makePrayerTime(.ashar, hours: asharTime, date: date),
            makePrayerTime(.maghrib, hours: maghribTime, date: date),
            makePrayerTime(.isya, hours: isyaTime, date: date),
        ]
    }

    // MARK: - Astronomical Calculations

    private func julianDate(year: Int, dayOfYear: Double) -> Double {
        return 367.0 * Double(year)
            - floor(7.0 * (Double(year) + floor((1.0 + 9.0) / 12.0)) / 4.0)
            + floor(275.0 * 1.0 / 9.0)
            + dayOfYear - 730531.5
    }

    private func sunDeclination(d: Double) -> Double {
        let g = fixAngle(357.529 + 0.98560028 * d)
        let q = fixAngle(280.459 + 0.98564736 * d)
        let l = fixAngle(q + 1.915 * sin(deg2rad(g)) + 0.020 * sin(deg2rad(2 * g)))
        let e = 23.439 - 0.00000036 * d
        return rad2deg(asin(sin(deg2rad(e)) * sin(deg2rad(l))))
    }

    private func equationOfTime(d: Double) -> Double {
        let g = fixAngle(357.529 + 0.98560028 * d)
        let q = fixAngle(280.459 + 0.98564736 * d)
        let l = fixAngle(q + 1.915 * sin(deg2rad(g)) + 0.020 * sin(deg2rad(2 * g)))
        let e = 23.439 - 0.00000036 * d
        let ra = rad2deg(atan2(cos(deg2rad(e)) * sin(deg2rad(l)), cos(deg2rad(l)))) / 15.0
        return q / 15.0 - fixHour(ra)
    }

    private func solarNoon(eqOfTime: Double) -> Double {
        return fixHour(12.0 + timezone - longitude / 15.0 - eqOfTime)
    }

    private func hourAngle(angle: Double, decl: Double) -> Double {
        let cosHA = (sin(deg2rad(-angle)) - sin(deg2rad(latitude)) * sin(deg2rad(decl)))
            / (cos(deg2rad(latitude)) * cos(deg2rad(decl)))
        return rad2deg(acos(cosHA))
    }

    private func asharHourAngle(decl: Double) -> Double {
        let shadowRatio = 1.0 + tan(deg2rad(abs(latitude - decl)))
        let angle = rad2deg(atan(1.0 / shadowRatio))
        return hourAngle(angle: 90.0 - angle, decl: decl)
    }

    // MARK: - Helpers

    private func makePrayerTime(_ name: PrayerName, hours: Double, date: Date) -> PrayerTime {
        let cal = Calendar.current
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60.0)
        var components = cal.dateComponents([.year, .month, .day], from: date)
        components.hour = h
        components.minute = m
        components.second = 0
        return PrayerTime(name: name, time: cal.date(from: components) ?? date)
    }

    private func deg2rad(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private func rad2deg(_ rad: Double) -> Double { rad * 180.0 / .pi }

    private func fixAngle(_ a: Double) -> Double {
        var result = a.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }

    private func fixHour(_ h: Double) -> Double {
        var result = h.truncatingRemainder(dividingBy: 24.0)
        if result < 0 { result += 24.0 }
        return result
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `cd /Users/user/Development/JadwalSolat && swift test --filter PrayerCalculatorTests`
Expected: All 4 tests PASS

**Step 5: Commit**

```bash
git add Sources/JadwalSolat/Models/PrayerCalculator.swift Tests/JadwalSolatTests/PrayerCalculatorTests.swift
git commit -m "feat: add prayer time calculator with Kemenag RI method"
```

---

### Task 4: Location Service

**Files:**
- Create: `Sources/JadwalSolat/Services/LocationService.swift`

**Step 1: Implement LocationService**

```swift
import Foundation
import CoreLocation

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var latitude: Double = -6.2088   // Default: Jakarta
    @Published var longitude: Double = 106.8456
    @Published var timezone: Double = 7.0
    @Published var cityName: String = "Jakarta"
    @Published var authorized: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()

        Task { @MainActor in
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.timezone = Double(TimeZone.current.secondsFromGMT()) / 3600.0
            self.authorized = true
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep default coordinates on failure
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            Task { @MainActor in
                if let p = placemarks?.first {
                    self.cityName = [p.locality, p.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }
            }
        }
    }
}
```

**Step 2: Verify it builds**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/JadwalSolat/Services/LocationService.swift
git commit -m "feat: add location service with auto-detect and reverse geocoding"
```

---

### Task 5: Notification Service

**Files:**
- Create: `Sources/JadwalSolat/Services/NotificationService.swift`

**Step 1: Implement NotificationService**

```swift
import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleNotifications(for prayers: [PrayerTime]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for prayer in prayers {
            guard prayer.name != .imsak else { continue } // Skip imsak, only show for actual prayers

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
```

**Step 2: Verify it builds**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/JadwalSolat/Services/NotificationService.swift
git commit -m "feat: add notification service for prayer time alerts"
```

---

### Task 6: Menu Bar App Entry Point + AppDelegate

**Files:**
- Modify: `Sources/JadwalSolat/main.swift`
- Create: `Sources/JadwalSolat/AppDelegate.swift`

**Step 1: Create AppDelegate with menu bar setup**

```swift
import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: Timer?
    var locationService = LocationService()
    var calculator: PrayerCalculator?
    var todayPrayers: [PrayerTime] = []
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Setup status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 350)
        popover.behavior = .transient

        // Listen for location updates
        locationService.$latitude.combineLatest(locationService.$longitude)
            .sink { [weak self] lat, lon in
                self?.calculator = PrayerCalculator(latitude: lat, longitude: lon, timezone: self?.locationService.timezone ?? 7.0)
                self?.refreshPrayerTimes()
            }
            .store(in: &cancellables)

        // Request location
        locationService.requestLocation()

        // Initial calculation with defaults
        calculator = PrayerCalculator(
            latitude: locationService.latitude,
            longitude: locationService.longitude,
            timezone: locationService.timezone
        )
        refreshPrayerTimes()

        // Setup click handler
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Update every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateMenuBarTitle()
        }

        // Request notification permission
        NotificationService.shared.requestPermission()
    }

    func refreshPrayerTimes() {
        guard let calculator = calculator else { return }
        todayPrayers = calculator.calculate(for: Date())
        NotificationService.shared.scheduleNotifications(for: todayPrayers)
        updateMenuBarTitle()
        updatePopoverContent()
    }

    func updateMenuBarTitle() {
        let now = Date()
        guard let next = PrayerTime.nextPrayer(from: todayPrayers, after: now) else {
            statusItem.button?.title = "🕌 —"
            return
        }
        let countdown = next.countdownString(from: now)
        statusItem.button?.title = "🕌 \(next.name.displayName) \(next.timeString) (\(countdown))"
    }

    func updatePopoverContent() {
        let view = PrayerMenuView(
            prayers: todayPrayers,
            cityName: locationService.cityName,
            onQuit: { NSApp.terminate(nil) }
        )
        popover.contentViewController = NSHostingController(rootView: view)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Refresh data when opening
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
```

**Step 2: Update main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

**Step 3: Verify it builds**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Will fail — PrayerMenuView not yet created (expected, proceed to Task 7)

**Step 4: Commit (partial — will complete after Task 7)**

Hold commit until Task 7 completes.

---

### Task 7: Prayer Menu View (Dropdown UI)

**Files:**
- Create: `Sources/JadwalSolat/Views/PrayerMenuView.swift`

**Step 1: Create PrayerMenuView**

```swift
import SwiftUI

struct PrayerMenuView: View {
    let prayers: [PrayerTime]
    let cityName: String
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("Jadwal Solat")
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 12)

            // Prayer times list
            VStack(spacing: 0) {
                ForEach(prayers, id: \.name) { prayer in
                    let isNext = isNextPrayer(prayer)
                    HStack {
                        Text(prayer.name.displayName)
                            .fontWeight(isNext ? .semibold : .regular)
                        Spacer()
                        Text(prayer.timeString)
                            .monospacedDigit()
                            .fontWeight(isNext ? .semibold : .regular)
                        if isNext {
                            Text("◀")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isNext ? Color.accentColor.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 12)

            // Footer
            HStack {
                Spacer()
                Button("Quit") {
                    onQuit()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(8)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .frame(width: 260)
    }

    private func isNextPrayer(_ prayer: PrayerTime) -> Bool {
        let next = PrayerTime.nextPrayer(from: prayers, after: Date())
        return next?.name == prayer.name
    }
}
```

**Step 2: Build the full app**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Build succeeded

**Step 3: Run the app to verify it works**

Run: `cd /Users/user/Development/JadwalSolat && .build/debug/JadwalSolat &`
Expected: Menu bar icon appears with prayer time + countdown. Click to see dropdown.

**Step 4: Commit everything from Task 6 + 7**

```bash
git add Sources/
git commit -m "feat: add menu bar app with prayer time dropdown and notifications"
```

---

### Task 8: Entitlements & Info.plist for Location + Notifications

**Files:**
- Create: `Sources/JadwalSolat/Info.plist`
- Create: `Sources/JadwalSolat/JadwalSolat.entitlements`
- Modify: `Package.swift` (if needed to reference Info.plist)

**Step 1: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Jadwal Solat membutuhkan lokasi untuk menghitung waktu solat yang akurat di daerah Anda.</string>
</dict>
</plist>
```

**Step 2: Create entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.personal-information.location</key>
    <true/>
</dict>
</plist>
```

**Step 3: Build and verify**

Run: `cd /Users/user/Development/JadwalSolat && swift build`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Sources/JadwalSolat/Info.plist Sources/JadwalSolat/JadwalSolat.entitlements
git commit -m "feat: add Info.plist and entitlements for location and no-dock"
```

---

### Task 9: Final Integration Test

**Step 1: Run all tests**

Run: `cd /Users/user/Development/JadwalSolat && swift test`
Expected: All tests pass

**Step 2: Build release**

Run: `cd /Users/user/Development/JadwalSolat && swift build -c release`
Expected: Build succeeded

**Step 3: Manual test**

Run: `cd /Users/user/Development/JadwalSolat && .build/release/JadwalSolat &`
Expected:
- Menu bar shows `🕌 [NextPrayer] HH:mm (Xm)`
- Clicking shows dropdown with all 6 prayer times
- Location auto-detected and shown
- Quit button works

**Step 4: Final commit if any cleanup needed**

```bash
git add -A
git commit -m "chore: final cleanup and integration"
```
