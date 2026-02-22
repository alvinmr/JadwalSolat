import Foundation
import CoreLocation

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var latitude: Double = -6.2088   // Default: Jakarta
    @Published var longitude: Double = 106.8456
    @Published var timezone: Double = Double(TimeZone.current.secondsFromGMT()) / 3600.0
    @Published var cityName: String = ""
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

        let coord = location.coordinate
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.authorized = true

                // Get timezone from placemark (location-accurate) or fallback to system
                if let placemarkTZ = placemark?.timeZone {
                    self.timezone = Double(placemarkTZ.secondsFromGMT()) / 3600.0
                } else {
                    self.timezone = Double(TimeZone.current.secondsFromGMT()) / 3600.0
                }

                // Set city name
                if let p = placemark {
                    self.cityName = [p.locality, p.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }

                // Set coordinates LAST so Combine subscribers see correct timezone
                self.latitude = coord.latitude
                self.longitude = coord.longitude
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep default coordinates on failure
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorized || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
