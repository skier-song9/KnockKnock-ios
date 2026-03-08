import Foundation
import SwiftUI

struct NearbyUser: Identifiable, Codable {
    let id: String  // deviceId
    let destinationStopName: String
    let remainingStops: Int
    let rank: Int
    let currentGps: GpsCoordinate
    let isPrivate: Bool

    // BLE proximity is merged locally after WebSocket users arrive.
    var proximitySample: ProximitySample?

    enum CodingKeys: String, CodingKey {
        case id
        case destinationStopName
        case remainingStops
        case rank
        case currentGps
        case isPrivate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        destinationStopName = try container.decode(String.self, forKey: .destinationStopName)
        remainingStops = try container.decode(Int.self, forKey: .remainingStops)
        rank = try container.decode(Int.self, forKey: .rank)
        currentGps = try container.decode(GpsCoordinate.self, forKey: .currentGps)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        proximitySample = nil
    }

    var proximityBin: ProximityBin {
        proximitySample?.bin ?? .unknown
    }

    // 레이더 배치용 (세션 내 고정 각도, deviceId 기반 — deterministic djb2 hash)
    var displayAngle: Double {
        // djb2 hash for deterministic angle across app launches
        let hash = id.utf8.reduce(5381) { ($0 &* 31) &+ Int($1) }
        return Double(abs(hash) % 360)
    }

    var sensorColor: Color {
        switch proximityBin {
        case .near: return .red
        case .mid: return .orange
        case .far: return .blue
        case .unknown: return .gray.opacity(0.6)
        }
    }

    var pulseSpeed: Double {
        switch remainingStops {
        case 1:  return Constants.pulseStop1
        case 2:  return Constants.pulseStop2
        case 3:  return Constants.pulseStop3
        default: return Constants.pulseDefault
        }
    }

    var fontSize: CGFloat {
        switch rank {
        case 1:  return 20
        case 2:  return 17
        case 3:  return 14
        default: return 12
        }
    }

    var labelOpacity: Double {
        switch rank {
        case 1:  return 1.0
        case 2:  return 0.85
        case 3:  return 0.7
        default: return 0.5
        }
    }

    var zIndex: Double {
        return Double(max(100 - (rank - 1) * 25, 25))
    }

    func applyingProximity(_ sample: ProximitySample?) -> NearbyUser {
        var updated = self
        updated.proximitySample = sample
        return updated
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
