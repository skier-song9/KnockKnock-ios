import Combine
import WatchConnectivity

final class WatchSessionService: NSObject, ObservableObject {
    static let shared = WatchSessionService()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendToWatch(_ users: [NearbyUser]) {
        guard WCSession.default.isReachable else { return }

        let data = users.prefix(5).map { user in
            [
                "name": user.destinationStopName,
                "remaining": user.remainingStops,
                "rank": user.rank,
            ] as [String: Any]
        }

        WCSession.default.sendMessage(["users": data], replyHandler: nil)
    }
}

extension WatchSessionService: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
