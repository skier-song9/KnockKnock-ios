import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: Double = 0  // 나침반 방향 (0=북)
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 5  // 5도 이상 변할 때만 업데이트
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionAndStart() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func startUpdating() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func arrowAngle(to target: GpsCoordinate) -> Double {
        guard let loc = currentLocation else { return 0 }
        let targetCoord = CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng)
        return BearingCalculator.arrowAngle(
            myLocation: loc,
            targetLocation: targetCoord,
            heading: currentHeading
        )
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
}
