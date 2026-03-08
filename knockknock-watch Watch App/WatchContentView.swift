import Combine
import SwiftUI
import WatchConnectivity

struct WatchContentView: View {
    @StateObject private var session = WatchSessionManager()

    var body: some View {
        NavigationStack {
            Group {
                if session.nearbyUsers.isEmpty {
                    VStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2)
                        Text("탐색 중...")
                            .font(.footnote)
                    }
                } else {
                    List {
                        ForEach(session.nearbyUsers.indices, id: \.self) { idx in
                            let user = session.nearbyUsers[idx]
                            HStack {
                                Text("\(user.rank).")
                                    .foregroundColor(rankColor(user.rank))
                                    .font(.caption.bold())

                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.footnote.bold())
                                    Text("\(user.remaining)정류장")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("KnockKnock")
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return .red
        case 2:
            return .orange
        case 3:
            return .yellow
        default:
            return .blue
        }
    }
}

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var nearbyUsers: [(name: String, remaining: Int, rank: Int)] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let users = message["users"] as? [[String: Any]] else { return }

        let parsed = users.compactMap { dict -> (name: String, remaining: Int, rank: Int)? in
            guard let name = dict["name"] as? String,
                  let remaining = dict["remaining"] as? Int,
                  let rank = dict["rank"] as? Int else { return nil }
            return (name, remaining, rank)
        }

        DispatchQueue.main.async {
            self.nearbyUsers = parsed
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}
