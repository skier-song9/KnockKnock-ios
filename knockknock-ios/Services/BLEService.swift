import CoreBluetooth
import Combine

final class BLEService: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!

    private let myDeviceId: String
    private var trackers: [String: DeviceTracker] = [:]
    private var cleanupTimer: Timer?
    private var isAdvertisingRequested = false
    private var isScanningRequested = false

    @Published var nearbyDeviceIds: [String] = []
    @Published private(set) var proximitySamples: [String: ProximitySample] = [:]

    init(deviceId: String) {
        self.myDeviceId = deviceId
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true])
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)

        cleanupTimer = Timer.scheduledTimer(withTimeInterval: Constants.bleTrackerCleanupInterval, repeats: true) { [weak self] _ in
            self?.cleanupStaleDevices()
        }
    }

    // MARK: - Advertising

    func startAdvertising() {
        isAdvertisingRequested = true
        startAdvertisingIfPossible()
    }

    func stopAdvertising() {
        isAdvertisingRequested = false
        peripheralManager.stopAdvertising()
    }

    // MARK: - Scanning

    func startScanning() {
        isScanningRequested = true
        startScanningIfPossible()
    }

    func stopScanning() {
        isScanningRequested = false
        centralManager.stopScan()
    }

    func reset() {
        trackers.removeAll()
        nearbyDeviceIds = []
        proximitySamples = [:]
    }

    // MARK: - Cleanup

    private func cleanupStaleDevices() {
        let now = Date()
        var didChange = false

        for deviceId in trackers.keys.sorted() {
            guard var tracker = trackers[deviceId] else { continue }
            let age = now.timeIntervalSince(tracker.lastSeenAt)

            if age >= Constants.bleRemovalTimeout {
                trackers.removeValue(forKey: deviceId)
                didChange = true
                continue
            }

            if age >= Constants.bleUnknownTimeout, tracker.currentBin != .unknown {
                tracker.currentBin = .unknown
                trackers[deviceId] = tracker
                didChange = true
            }
        }

        if didChange {
            publishState()
        }
    }

    private func startAdvertisingIfPossible() {
        guard isAdvertisingRequested,
              peripheralManager.state == .poweredOn,
              let payload = AdvertisementPayloadV1(stableDeviceId: myDeviceId) else {
            return
        }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [Constants.knockKnockServiceUUID],
            CBAdvertisementDataLocalNameKey: payload.localName,
        ]
        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising(advertisementData)
    }

    private func startScanningIfPossible() {
        guard isScanningRequested, centralManager.state == .poweredOn else { return }

        if centralManager.isScanning {
            centralManager.stopScan()
        }

        centralManager.scanForPeripherals(
            withServices: [Constants.knockKnockServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    private func handleDiscovery(localName: String, rssi: Int, seenAt: Date = Date()) {
        guard let payload = AdvertisementPayloadV1.decode(localName: localName),
              payload.stableDeviceId != myDeviceId else {
            return
        }

        var tracker = trackers[payload.stableDeviceId] ?? DeviceTracker(
            deviceId: payload.stableDeviceId,
            txPowerAt1m: Int(payload.txPowerAt1m),
            recentRssi: [],
            filteredRssi: nil,
            lastSeenAt: seenAt,
            currentBin: .unknown
        )

        tracker.txPowerAt1m = Int(payload.txPowerAt1m)
        tracker.lastSeenAt = seenAt
        tracker.recentRssi.append(rssi)
        if tracker.recentRssi.count > 5 {
            tracker.recentRssi.removeFirst(tracker.recentRssi.count - 5)
        }

        tracker.filteredRssi = median(of: tracker.recentRssi)
        if tracker.recentRssi.count >= 2, let filteredRssi = tracker.filteredRssi {
            let pathLoss = Double(tracker.txPowerAt1m) - filteredRssi
            tracker.currentBin = nextBin(for: pathLoss, current: tracker.currentBin)
        } else {
            tracker.currentBin = .unknown
        }

        trackers[payload.stableDeviceId] = tracker
        publishState()
    }

    private func publishState() {
        nearbyDeviceIds = trackers.keys.sorted()
        proximitySamples = trackers.mapValues { tracker in
            let pathLoss = tracker.filteredRssi.map { Double(tracker.txPowerAt1m) - $0 }
            return ProximitySample(
                deviceId: tracker.deviceId,
                txPowerAt1m: tracker.txPowerAt1m,
                filteredRssi: tracker.filteredRssi,
                pathLoss: pathLoss,
                lastSeenAt: tracker.lastSeenAt,
                bin: tracker.currentBin
            )
        }
    }

    private func median(of values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return Double(sorted[middle - 1] + sorted[middle]) / 2.0
        }

        return Double(sorted[middle])
    }

    private func nextBin(for pathLoss: Double, current: ProximityBin) -> ProximityBin {
        switch current {
        case .near:
            return pathLoss > 18 ? .mid : .near
        case .mid:
            if pathLoss <= 12 { return .near }
            if pathLoss > 28 { return .far }
            return .mid
        case .far:
            return pathLoss <= 22 ? .mid : .far
        case .unknown:
            if pathLoss <= 15 { return .near }
            if pathLoss <= 25 { return .mid }
            return .far
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }
}

private struct DeviceTracker {
    let deviceId: String
    var txPowerAt1m: Int
    var recentRssi: [Int]
    var filteredRssi: Double?
    var lastSeenAt: Date
    var currentBin: ProximityBin
}

// MARK: - CBCentralManagerDelegate

extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanningIfPossible()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard RSSI.intValue != 127,
              let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }

        handleDiscovery(localName: localName, rssi: RSSI.intValue)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertisingIfPossible()
        }
    }
}
