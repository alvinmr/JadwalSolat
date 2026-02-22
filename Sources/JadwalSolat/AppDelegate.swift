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
    let settings = AppSettings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Setup status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient

        // Listen for location updates (only used in automatic mode)
        locationService.$latitude.combineLatest(locationService.$longitude)
            .sink { [weak self] _, _ in
                self?.rebuildCalculator()
            }
            .store(in: &cancellables)

        // Listen for settings changes
        settings.$calculationMethod
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$locationMode
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$manualLatitude
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$manualLongitude
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$menuBarFormat
            .sink { [weak self] _ in self?.updateMenuBarTitle() }
            .store(in: &cancellables)

        // Request location
        locationService.requestLocation()

        // Initial calculation
        rebuildCalculator()

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

    func rebuildCalculator() {
        let lat: Double
        let lon: Double
        let tz: Double

        if settings.locationMode == .manual {
            lat = settings.manualLatitude
            lon = settings.manualLongitude
            // Estimate timezone from longitude for manual mode
            tz = round(lon / 15.0)
        } else {
            lat = locationService.latitude
            lon = locationService.longitude
            tz = locationService.timezone
        }

        calculator = PrayerCalculator(
            latitude: lat,
            longitude: lon,
            timezone: tz,
            method: settings.calculationMethod
        )
        refreshPrayerTimes()
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

        if statusItem.button?.image == nil {
            if let image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Jadwal Solat") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                let sized = image.withSymbolConfiguration(config) ?? image
                sized.isTemplate = true
                statusItem.button?.image = sized
                statusItem.button?.imagePosition = .imageLeading
            }
        }

        guard let next = PrayerTime.nextPrayer(from: todayPrayers, after: now) else {
            statusItem.button?.title = "—"
            return
        }
        let countdown = next.countdownString(from: now)
        let name = next.name.displayName
        let time = next.timeString

        switch settings.menuBarFormat {
        case .full:
            statusItem.button?.title = "\(name) \(time) (\(countdown))"
        case .nameCountdown:
            statusItem.button?.title = "\(name) (\(countdown))"
        case .countdownOnly:
            statusItem.button?.title = "\(countdown)"
        case .timeOnly:
            statusItem.button?.title = "\(name) \(time)"
        }
    }

    func updatePopoverContent() {
        let cityName = settings.locationMode == .manual
            ? "Manual (\(String(format: "%.2f", settings.manualLatitude)), \(String(format: "%.2f", settings.manualLongitude)))"
            : locationService.cityName

        let view = ContentView(
            prayers: todayPrayers,
            cityName: cityName,
            onQuit: { NSApp.terminate(nil) },
            notificationPreferences: NotificationPreferences.shared,
            settings: self.settings,
            onSettingsChanged: { [weak self] in
                self?.rebuildCalculator()
            }
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
