import CoreBluetooth
import Combine

protocol BLEServiceDelegate: AnyObject {
    func bleService(_ service: BLEService, didDiscover deviceId: String, rssi: Int)
    func bleService(_ service: BLEService, didLose deviceId: String)
}

final class BLEService: NSObject, ObservableObject {
    weak var delegate: BLEServiceDelegate?

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!

    private let myDeviceId: String
    private var discoveredDevices: [UUID: (deviceId: String, lastSeen: Date)] = [:]
    private var cleanupTimer: Timer?

    @Published var nearbyDeviceIds: [String] = []

    init(deviceId: String) {
        self.myDeviceId = deviceId
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true])
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)

        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.cleanupStaleDevices()
        }
    }

    // MARK: - Advertising

    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else { return }
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [Constants.knockKnockServiceUUID],
            CBAdvertisementDataLocalNameKey: myDeviceId,
        ]
        peripheralManager.startAdvertising(advertisementData)
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }

    // MARK: - Scanning

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [Constants.knockKnockServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    // MARK: - Cleanup

    private func cleanupStaleDevices() {
        let threshold = Date().addingTimeInterval(-30)
        let stale = discoveredDevices.filter { $0.value.lastSeen < threshold }
        for (uuid, entry) in stale {
            discoveredDevices.removeValue(forKey: uuid)
            nearbyDeviceIds.removeAll { $0 == entry.deviceId }
            delegate?.bleService(self, didLose: entry.deviceId)
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard let deviceId = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
              deviceId != myDeviceId else { return }

        discoveredDevices[peripheral.identifier] = (deviceId, Date())

        if !nearbyDeviceIds.contains(deviceId) {
            nearbyDeviceIds.append(deviceId)
        }

        delegate?.bleService(self, didDiscover: deviceId, rssi: RSSI.intValue)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        }
    }
}
