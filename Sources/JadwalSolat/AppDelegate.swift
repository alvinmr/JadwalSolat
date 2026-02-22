import AppKit
import SwiftUI
import Combine

@MainActor
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
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient

        // Listen for location updates
        locationService.$latitude.combineLatest(locationService.$longitude)
            .sink { [weak self] lat, lon in
                guard let self else { return }
                self.calculator = PrayerCalculator(latitude: lat, longitude: lon, timezone: self.locationService.timezone)
                self.refreshPrayerTimes()
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
            Task { @MainActor in
                self?.updateMenuBarTitle()
            }
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
            statusItem.button?.title = "\u{1F54C} —"
            return
        }
        let countdown = next.countdownString(from: now)
        statusItem.button?.title = "\u{1F54C} \(next.name.displayName) \(next.timeString) (\(countdown))"
    }

    func updatePopoverContent() {
        let view = PrayerMenuView(
            prayers: todayPrayers,
            cityName: locationService.cityName,
            onQuit: { NSApp.terminate(nil) },
            notificationPreferences: NotificationPreferences.shared
        )
        popover.contentViewController = NSHostingController(rootView: view)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
