import Foundation
import CoreLocation

struct TransitStop: Identifiable, Codable {
    let id: String          // 정류장 고유 ID
    let name: String        // 정류장 이름
    let coordinate: StopCoordinate
    let routeId: String     // 소속 노선
    let stopIndex: Int      // 노선 내 순번

    struct StopCoordinate: Codable {
        let latitude: Double
        let longitude: Double

        var clLocation: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
