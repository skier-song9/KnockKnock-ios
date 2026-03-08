import CoreBluetooth
import Foundation

enum Constants {
    // BLE
    static let knockKnockServiceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    static let sessionTokenCharUUID  = CBUUID(string: "B2C3D4E5-F6A1-8901-BCDE-F12345678901")
    static let bleDefaultTxPowerAt1m: Int8 = -59
    static let bleUnknownTimeout: TimeInterval = 8
    static let bleRemovalTimeout: TimeInterval = 15
    static let bleTrackerCleanupInterval: TimeInterval = 1

    // WebSocket
    static let wsBaseURL = AppConfig.wsBaseURL

    // Sensor pulse 속도 (초)
    static let pulseStop1: Double = 0.3
    static let pulseStop2: Double = 0.6
    static let pulseStop3: Double = 1.0
    static let pulseDefault: Double = 2.0

    // GPS 공유 정밀도 (소수점 3자리 = ±111m)
    static let gpsSharePrecision = 3
}
