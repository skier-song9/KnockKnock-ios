import Combine
import CoreLocation
import SwiftUI

struct NearbyStopsView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (TransitStop) -> Void

    @State private var stops: [TransitStop] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("가까운 정류장 찾는 중...")
                    .padding()
            } else if let errorMessage {
                ContentUnavailableView(errorMessage, systemImage: "location.slash")
            } else if stops.isEmpty {
                ContentUnavailableView("근처 정류장 없음", systemImage: "bus")
            } else {
                List(stops) { stop in
                    Button {
                        onSelect(stop)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(stop.name)
                                .font(.body)
                            Text("노선: \(stop.routeId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            loadNearbyStops()
        }
        .onReceive(appState.locationService.$currentLocation.compactMap { $0 }) { _ in
            if stops.isEmpty && !isLoading {
                loadNearbyStops()
            }
        }
    }

    private func loadNearbyStops() {
        guard let location = appState.locationService.currentLocation else {
            appState.locationService.requestPermissionAndStart()
            errorMessage = "위치 권한이 필요합니다"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            let fetched = (try? await appState.transitService.nearbyStops(location: location)) ?? []
            await MainActor.run {
                stops = fetched
                isLoading = false
                if fetched.isEmpty {
                    errorMessage = nil
                }
            }
        }
    }
}
