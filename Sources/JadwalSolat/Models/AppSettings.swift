import Foundation
import ServiceManagement

enum CalculationMethod: String, CaseIterable, Identifiable {
    case kemenagRI = "Kemenag RI"
    case mwl = "MWL"
    case isna = "ISNA"
    case ummAlQura = "Umm Al-Qura"
    case egyptian = "Egyptian"

    var id: String { rawValue }

    var subuhAngle: Double {
        switch self {
        case .kemenagRI: return 20.0
        case .mwl: return 18.0
        case .isna: return 15.0
        case .ummAlQura: return 18.5
        case .egyptian: return 19.5
        }
    }

    var isyaAngle: Double? {
        switch self {
        case .kemenagRI: return 18.0
        case .mwl: return 17.0
        case .isna: return 15.0
        case .ummAlQura: return nil // 90 min after Maghrib
        case .egyptian: return 17.5
        }
    }

    /// For Umm Al-Qura: Isya = Maghrib + 90 minutes
    var isyaMinutesAfterMaghrib: Double? {
        switch self {
        case .ummAlQura: return 90.0
        default: return nil
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
    @Published var manualLatitude: Double {
        didSet { save() }
    }
    @Published var manualLongitude: Double {
        didSet { save() }
    }
    @Published var menuBarFormat: MenuBarFormat {
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
        self.manualLatitude = defaults.object(forKey: "manualLatitude") as? Double ?? -8.65
        self.manualLongitude = defaults.object(forKey: "manualLongitude") as? Double ?? 115.22
        self.menuBarFormat = MenuBarFormat(rawValue: defaults.string(forKey: "menuBarFormat") ?? "") ?? .full
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(calculationMethod.rawValue, forKey: "calculationMethod")
        defaults.set(locationMode.rawValue, forKey: "locationMode")
        defaults.set(manualLatitude, forKey: "manualLatitude")
        defaults.set(manualLongitude, forKey: "manualLongitude")
        defaults.set(menuBarFormat.rawValue, forKey: "menuBarFormat")
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
