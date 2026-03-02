import AppKit
import SwiftUI
import Combine
import UserNotifications

func diskLog(_ msg: String) {
    let url = URL(fileURLWithPath: "/tmp/jadwal_solat.log")
    let txt = "[\(Date())] \(msg)\n"
    if let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile()
        if let data = txt.data(using: .utf8) {
            handle.write(data)
        }
        try? handle.close()
    } else {
        try? txt.write(to: url, atomically: true, encoding: .utf8)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timer: Timer?
    var locationService = LocationService()
    var apiService: PrayerAPIService?
    var todayPrayers: [PrayerTime] = []
    var tomorrowPrayers: [PrayerTime] = []
    var lastCalculationDate = Date()
    var currentFetchTask: Task<Void, Never>?
    var cancellables = Set<AnyCancellable>()
    let settings = AppSettings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        diskLog("applicationDidFinishLaunching STARTED")
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
            .dropFirst()
            .sink { [weak self] _, _ in
                self?.rebuildCalculator()
            }
            .store(in: &cancellables)

        // Listen for settings changes
        settings.$calculationMethod
            .dropFirst()
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$locationMode
            .dropFirst()
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$manualCity
            .dropFirst()
            .sink { [weak self] _ in self?.rebuildCalculator() }
            .store(in: &cancellables)
        settings.$menuBarFormat
            .dropFirst()
            .sink { [weak self] _ in self?.updateMenuBarTitle() }
            .store(in: &cancellables)

        // Request location
        locationService.requestLocation()

        // Force initial calculation
        rebuildCalculator()

        // Setup click handler
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Update every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            Task { @MainActor in
                let now = Date()
                if !Calendar.current.isDate(strongSelf.lastCalculationDate, inSameDayAs: now) {
                    await strongSelf.refreshPrayerTimes()
                } else {
                    strongSelf.updateMenuBarTitle()
                }
            }
        }

        // Request notification permission
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.requestPermission()
    }

    func rebuildCalculator() {
        let addressStr: String

        if settings.locationMode == .manual {
            addressStr = settings.manualCity
        } else {
            addressStr = locationService.cityName.isEmpty ? "Jakarta" : locationService.cityName
        }

        apiService = PrayerAPIService(
            address: addressStr,
            method: settings.calculationMethod
        )
        
        currentFetchTask?.cancel()
        currentFetchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            await refreshPrayerTimes()
        }
    }


    func refreshPrayerTimes() async {
        guard let apiService = apiService else { 
            print("apiService is nil")
            return 
        }
        let now = Date()
        self.lastCalculationDate = now
        
        diskLog("refreshPrayerTimes executing. Address: \(apiService.address) Method: \(apiService.method.apiMethodId)")
        
        do {
            diskLog("Fetching today's schedule...")
            let fetchedToday = try await apiService.fetch(for: now)
            diskLog("Fetched today! Count: \(fetchedToday.count)")
            
            var fetchedTomorrow: [PrayerTime] = []
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) {
                diskLog("Fetching tomorrow's schedule...")
                fetchedTomorrow = try await apiService.fetch(for: tomorrow)
                diskLog("Fetched tomorrow! Count: \(fetchedTomorrow.count)")
            }
            
            self.todayPrayers = fetchedToday
            self.tomorrowPrayers = fetchedTomorrow
            
            // Schedule notifications for both today and tomorrow so there is always something pending
            NotificationService.shared.scheduleNotifications(for: todayPrayers + tomorrowPrayers)
            
            await MainActor.run {
                updateMenuBarTitle()
                updatePopoverContent()
            }
        } catch {
            diskLog("Failed to fetch API: \(error.localizedDescription) - \(error)")
            // On failure, we retain the existing schedules (if any) and update the UI.
            await MainActor.run {
                updateMenuBarTitle()
                updatePopoverContent()
            }
        }
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

        let next: PrayerTime
        if let n = PrayerTime.nextPrayer(from: todayPrayers, after: now) {
            next = n
        } else if let nextTomorrow = tomorrowPrayers.first {
            next = nextTomorrow
        } else {
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
            ? "Manual (\(settings.manualCity))"
            : locationService.cityName

        let view = ContentView(
            prayers: todayPrayers,
            tomorrowPrayers: tomorrowPrayers,
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
    
    // MARK: - UNUserNotificationCenterDelegate
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even if app is frontmost
        completionHandler([.banner, .sound])
    }
}
