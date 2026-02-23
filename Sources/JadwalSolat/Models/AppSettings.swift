import Foundation
import ServiceManagement

enum CalculationMethod: String, CaseIterable, Identifiable {
    case kemenagRI = "Kemenag RI"
    case mwl = "MWL"
    case isna = "ISNA"
    case ummAlQura = "Umm Al-Qura"
    case egyptian = "Egyptian"

    var id: String { rawValue }

    // AlAdhan API method IDs
    var apiMethodId: Int {
        switch self {
        case .kemenagRI: return 20   // Ministry of Religious Affairs, Indonesia
        case .mwl: return 3          // Muslim World League
        case .isna: return 2         // Islamic Society of North America (ISNA)
        case .ummAlQura: return 4    // Umm Al-Qura University, Makkah
        case .egyptian: return 5     // Egyptian General Authority of Survey
        }
    }
}

enum LocationMode: String, CaseIterable {
    case automatic = "Otomatis (GPS)"
    case manual = "Manual"
}

enum MenuBarFormat: String, CaseIterable, Identifiable {
    case full = "Solat + Waktu + Countdown"
    case nameCountdown = "Solat + Countdown"
    case countdownOnly = "Countdown saja"
    case timeOnly = "Waktu solat saja"

    var id: String { rawValue }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var calculationMethod: CalculationMethod {
        didSet { save() }
    }
    @Published var locationMode: LocationMode {
        didSet { save() }
    }
    @Published var manualCity: String {
        didSet { save() }
    }
    @Published var menuBarFormat: MenuBarFormat {
        didSet { save() }
    }
    @Published var hijriyahOffset: Int {
        didSet { save() }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            save()
            updateLoginItem()
        }
    }

    init() {
        let defaults = UserDefaults.standard
        self.calculationMethod = CalculationMethod(rawValue: defaults.string(forKey: "calculationMethod") ?? "") ?? .kemenagRI
        self.locationMode = LocationMode(rawValue: defaults.string(forKey: "locationMode") ?? "") ?? .automatic
        self.manualCity = defaults.string(forKey: "manualCity") ?? "Jakarta, Indonesia"
        self.menuBarFormat = MenuBarFormat(rawValue: defaults.string(forKey: "menuBarFormat") ?? "") ?? .full
        self.hijriyahOffset = defaults.integer(forKey: "hijriyahOffset")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(calculationMethod.rawValue, forKey: "calculationMethod")
        defaults.set(locationMode.rawValue, forKey: "locationMode")
        defaults.set(manualCity, forKey: "manualCity")
        defaults.set(menuBarFormat.rawValue, forKey: "menuBarFormat")
        defaults.set(hijriyahOffset, forKey: "hijriyahOffset")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — login item management may require app bundle
            }
        }
    }
}
