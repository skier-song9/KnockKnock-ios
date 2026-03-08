import Combine
import CoreLocation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // Services
    let bleService: BLEService
    let wsService: WebSocketService
    let locationService: LocationService
    let transitService: TransitAPIService
    private let watchSessionService = WatchSessionService.shared

    // User state
    @Published var transportType: TransportType?
    @Published var selectedStop: TransitStop?
    @Published var isPrivate: Bool = false
    @Published var isSearching: Bool = false
    @Published var isUIHidden: Bool = false

    // Radar state
    @Published var nearbyUsers: [NearbyUser] = []
    @Published var arrowAngle: Double = 0

    private var bindingsCancellables = Set<AnyCancellable>()
    private var searchCancellables = Set<AnyCancellable>()
    private let deviceId = UserSession.makeDeviceId()
    private var lastJoinSignature: String?
    private var serverNearbyUsers: [NearbyUser] = []

    init() {
        bleService = BLEService(deviceId: deviceId)
        wsService = WebSocketService()
        locationService = LocationService()
        transitService = TransitAPIService()

        setupBindings()
    }

    // MARK: - Search Flow

    func startSearching() {
        guard !isSearching,
              selectedStop != nil,
              transportType != nil else { return }

        isSearching = true
        lastJoinSignature = nil

        wsService.connect()
        bleService.startAdvertising()
        bleService.startScanning()

        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermissionAndStart()
        } else {
            locationService.startUpdating()
        }

        bindSearchSession()
        attemptRoomJoin()
    }

    func stopSearching() {
        guard isSearching else { return }

        isSearching = false
        bleService.stopAdvertising()
        bleService.stopScanning()
        bleService.reset()
        wsService.disconnect()
        locationService.stopUpdating()
        serverNearbyUsers = []
        nearbyUsers = []
        arrowAngle = 0
        isUIHidden = false
        lastJoinSignature = nil
        searchCancellables.removeAll()
    }

    // MARK: - Bindings

    private func setupBindings() {
        wsService.$nearbyUsers
            .sink { [weak self] users in
                self?.serverNearbyUsers = users
                self?.mergeNearbyUsers()
            }
            .store(in: &bindingsCancellables)

        bleService.$proximitySamples
            .sink { [weak self] _ in
                self?.mergeNearbyUsers()
            }
            .store(in: &bindingsCancellables)

        locationService.$currentLocation
            .compactMap { $0 }
            .throttle(for: .seconds(5), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] location in
                guard let self, self.isSearching else { return }
                let gps = GpsCoordinate(lat: location.latitude, lng: location.longitude)
                self.wsService.updateSession(gps: gps)
                self.updateArrowAngle()
            }
            .store(in: &bindingsCancellables)

        locationService.$currentHeading
            .sink { [weak self] _ in
                self?.updateArrowAngle()
            }
            .store(in: &bindingsCancellables)

        $selectedStop
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] stop in
                guard let self else { return }
                self.lastJoinSignature = nil
                if self.isSearching {
                    self.wsService.updateSession(destination: stop)
                    self.attemptRoomJoin()
                }
            }
            .store(in: &bindingsCancellables)
    }

    private func bindSearchSession() {
        searchCancellables.removeAll()

        bleService.$nearbyDeviceIds
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.attemptRoomJoin()
            }
            .store(in: &searchCancellables)

        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.attemptRoomJoin()
            }
            .store(in: &searchCancellables)
    }

    private func attemptRoomJoin() {
        guard isSearching,
              let stop = selectedStop,
              let transport = transportType,
              let location = locationService.currentLocation else { return }

        let nearbyIds = bleService.nearbyDeviceIds.sorted()
        guard !nearbyIds.isEmpty else { return }

        let signature = "\(transport.rawValue)|\(stop.id)|\(nearbyIds.joined(separator: ","))"
        guard signature != lastJoinSignature else { return }

        let session = UserSession(
            deviceId: deviceId,
            roomId: "",
            transportType: transport,
            routeId: stop.routeId,
            destinationStopId: stop.id,
            destinationStopName: stop.name,
            destinationStopIndex: stop.stopIndex,
            currentGps: GpsCoordinate(lat: location.latitude, lng: location.longitude),
            isPrivate: isPrivate,
            lastSeen: ISO8601DateFormatter().string(from: Date())
        )

        wsService.joinRoom(
            deviceId: deviceId,
            nearbyDeviceIds: nearbyIds,
            currentStopIndex: 0,
            session: session
        )

        lastJoinSignature = signature
    }

    private func updateArrowAngle() {
        guard let rank1 = nearbyUsers.first(where: { $0.rank == 1 }) else {
            arrowAngle = 0
            return
        }

        arrowAngle = locationService.arrowAngle(to: rank1.currentGps)
    }

    private func mergeNearbyUsers() {
        let samplesByDeviceId = bleService.proximitySamples
        nearbyUsers = serverNearbyUsers.map { user in
            user.applyingProximity(samplesByDeviceId[user.id])
        }
        watchSessionService.sendToWatch(nearbyUsers)
        updateArrowAngle()
    }
}
