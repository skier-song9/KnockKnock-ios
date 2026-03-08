import CoreLocation

enum BearingCalculator {
    private static func normalizedAngle(_ angle: Double) -> Double {
        let wrapped = (angle + 360).truncatingRemainder(dividingBy: 360)
        if wrapped <= 0.5 || wrapped >= 359.5 {
            return 0
        }
        return wrapped
    }

    /// 두 좌표 간 방위각 계산 (0 = 북, 90 = 동, 180 = 남, 270 = 서)
    static func bearing(from: CLLocationCoordinate2D,
                        to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let bearing = atan2(y, x) * 180 / .pi
        return normalizedAngle(bearing)
    }

    /// 화살표 각도: 내 위치에서 목표를 향하는 방향 (나침반 heading 보정)
    static func arrowAngle(myLocation: CLLocationCoordinate2D,
                           targetLocation: CLLocationCoordinate2D,
                           heading: Double) -> Double {
        let b = bearing(from: myLocation, to: targetLocation)
        return normalizedAngle(b - heading)
    }
}
