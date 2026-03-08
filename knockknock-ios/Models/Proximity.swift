import Foundation

enum ProximityBin: String, Codable, Equatable {
    case near
    case mid
    case far
    case unknown
}

struct ProximitySample: Equatable {
    let deviceId: String
    let txPowerAt1m: Int
    let filteredRssi: Double?
    let pathLoss: Double?
    let lastSeenAt: Date
    let bin: ProximityBin
}

struct AdvertisementPayloadV1: Equatable {
    static let prefix = "KK1:"
    static let version: UInt8 = 0x01

    let stableDeviceId: String
    let txPowerAt1m: Int8

    init?(stableDeviceId: String, txPowerAt1m: Int8 = Constants.bleDefaultTxPowerAt1m) {
        guard let uuid = UUID(uuidString: stableDeviceId) else { return nil }
        self.stableDeviceId = uuid.uuidString.lowercased()
        self.txPowerAt1m = txPowerAt1m
    }

    var localName: String {
        AdvertisementPayloadV1.prefix + encodedPayload.base64URLEncodedString()
    }

    private var encodedPayload: Data {
        var data = Data([AdvertisementPayloadV1.version])
        data.append(uuidData(for: stableDeviceId))
        data.append(UInt8(bitPattern: txPowerAt1m))
        return data
    }

    static func decode(localName: String) -> AdvertisementPayloadV1? {
        guard localName.hasPrefix(prefix) else { return nil }
        let encoded = String(localName.dropFirst(prefix.count))
        guard let payloadData = Data(base64URLEncoded: encoded),
              payloadData.count == 18,
              payloadData.first == version else {
            return nil
        }

        let uuidBytes = payloadData[1...16]
        guard let deviceId = canonicalDeviceId(from: uuidBytes) else { return nil }
        let txPowerAt1m = Int8(bitPattern: payloadData[17])
        return AdvertisementPayloadV1(stableDeviceId: deviceId, txPowerAt1m: txPowerAt1m)
    }

    static func canonicalDeviceId(from string: String) -> String? {
        guard let uuid = UUID(uuidString: string) else { return nil }
        return uuid.uuidString.lowercased()
    }

    private static func canonicalDeviceId(from bytes: Data.SubSequence) -> String? {
        guard bytes.count == 16 else { return nil }
        let values = Array(bytes)
        let uuid = UUID(uuid: (
            values[0], values[1], values[2], values[3],
            values[4], values[5], values[6], values[7],
            values[8], values[9], values[10], values[11],
            values[12], values[13], values[14], values[15]
        ))
        return uuid.uuidString.lowercased()
    }

    private func uuidData(for string: String) -> Data {
        let uuid = UUID(uuidString: string) ?? UUID()
        var rawUUID = uuid.uuid
        return withUnsafeBytes(of: &rawUUID) { Data($0) }
    }
}

private extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - (base64.count % 4)) % 4
        if padding > 0 {
            base64.append(String(repeating: "=", count: padding))
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        self = data
    }

    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
