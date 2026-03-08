import Foundation
import SocketIO
import Combine

final class WebSocketService: ObservableObject {
    private var manager: SocketManager
    private var socket: SocketIOClient

    @Published var nearbyUsers: [NearbyUser] = []
    @Published var isConnected: Bool = false

    init(url: String = Constants.wsBaseURL) {
        manager = SocketManager(socketURL: URL(string: url)!,
                                config: [.log(false), .compress])
        socket = manager.defaultSocket
        setupHandlers()
    }

    // MARK: - Connection

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    // MARK: - Events

    func joinRoom(deviceId: String,
                  nearbyDeviceIds: [String],
                  currentStopIndex: Int,
                  session: UserSession) {
        let payload: [String: Any] = [
            "deviceId": deviceId,
            "nearbyDeviceIds": nearbyDeviceIds,
            "currentStopIndex": currentStopIndex,
            "session": [
                "transportType": session.transportType.rawValue,
                "routeId": session.routeId,
                "destinationStopId": session.destinationStopId,
                "destinationStopName": session.destinationStopName,
                "destinationStopIndex": session.destinationStopIndex,
                "currentGps": [
                    "lat": session.currentGps.rounded().lat,
                    "lng": session.currentGps.rounded().lng,
                ],
                "isPrivate": session.isPrivate,
            ],
        ]
        socket.emit("join_room", payload)
    }

    func updateSession(gps: GpsCoordinate? = nil,
                       destination: TransitStop? = nil,
                       isPrivate: Bool? = nil,
                       currentStopIndex: Int? = nil) {
        var payload: [String: Any] = [:]
        if let gps = gps {
            payload["currentGps"] = ["lat": gps.rounded().lat, "lng": gps.rounded().lng]
        }
        if let dest = destination {
            payload["destinationStopId"] = dest.id
            payload["destinationStopName"] = dest.name
            payload["destinationStopIndex"] = dest.stopIndex
        }
        if let isPrivate {
            payload["isPrivate"] = isPrivate
        }
        if let stopIndex = currentStopIndex {
            payload["currentStopIndex"] = stopIndex
        }
        if !payload.isEmpty {
            socket.emit("user_update", payload)
        }
    }

    // MARK: - Handlers

    private func setupHandlers() {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }

        socket.on("room_update") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let usersData = dict["rankedUsers"] as? [[String: Any]] else { return }

            let decoder = JSONDecoder()
            if let jsonData = try? JSONSerialization.data(withJSONObject: usersData),
               let users = try? decoder.decode([NearbyUser].self, from: jsonData) {
                DispatchQueue.main.async {
                    self.nearbyUsers = users
                }
            }
        }

        socket.on("user_left") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let deviceId = dict["deviceId"] as? String else { return }
            DispatchQueue.main.async {
                self?.nearbyUsers.removeAll { $0.id == deviceId }
            }
        }
    }
}
