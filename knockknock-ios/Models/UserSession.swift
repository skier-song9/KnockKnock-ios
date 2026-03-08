import Foundation
import Security

enum TransportType: String, Codable, CaseIterable {
    case bus = "bus"
    case subway = "subway"

    var displayName: String {
        switch self {
        case .bus: return "버스"
        case .subway: return "지하철"
        }
    }
}

struct UserSession: Codable, Equatable {
    let deviceId: String
    var roomId: String
    var transportType: TransportType
    var routeId: String
    var destinationStopId: String
    var destinationStopName: String
    var destinationStopIndex: Int
    var currentGps: GpsCoordinate
    var isPrivate: Bool
    var lastSeen: String

    static func makeDeviceId() -> String {
        let service = "com.knockknock.app"
        let account = "deviceId"

        // Try to read from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let data = result as? Data,
           let id = String(data: data, encoding: .utf8) {
            return id
        }

        // Generate new UUID and store in Keychain
        let newId = UUID().uuidString
        guard let data = newId.data(using: .utf8) else { return newId }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newId
    }
}

struct GpsCoordinate: Codable, Equatable {
    var lat: Double
    var lng: Double

    // 프라이버시: 소수점 3자리로 반올림
    func rounded() -> GpsCoordinate {
        let factor = pow(10.0, Double(Constants.gpsSharePrecision))
        return GpsCoordinate(
            lat: (lat * factor).rounded() / factor,
            lng: (lng * factor).rounded() / factor
        )
    }
}
