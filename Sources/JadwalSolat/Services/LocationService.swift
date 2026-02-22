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
            if status == .authorized || status == .authorizedAlways {
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
