import XCTest
import CoreLocation
@testable import knockknock_ios

final class knockknock_iosTests: XCTestCase {
    func test_bearingNorth() {
        let from = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        let to = CLLocationCoordinate2D(latitude: 38.0, longitude: 127.0)

        let bearing = BearingCalculator.bearing(from: from, to: to)
        XCTAssertEqual(bearing, 0, accuracy: 1.0)
    }

    func test_bearingEast() {
        let from = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        let to = CLLocationCoordinate2D(latitude: 37.0, longitude: 128.0)

        let bearing = BearingCalculator.bearing(from: from, to: to)
        XCTAssertEqual(bearing, 90, accuracy: 2.0)
    }

    func test_arrowAngle_pointsCorrectly() {
        let from = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        let to = CLLocationCoordinate2D(latitude: 37.0, longitude: 128.0)

        let arrow = BearingCalculator.arrowAngle(
            myLocation: from,
            targetLocation: to,
            heading: 0.0
        )

        XCTAssertEqual(arrow, 90, accuracy: 2.0)
    }

    func test_arrowAngle_compensatesHeading() {
        let from = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        let to = CLLocationCoordinate2D(latitude: 37.0, longitude: 128.0)

        let arrow = BearingCalculator.arrowAngle(
            myLocation: from,
            targetLocation: to,
            heading: 90.0
        )

        XCTAssertEqual(arrow, 0, accuracy: 2.0)
    }
}
