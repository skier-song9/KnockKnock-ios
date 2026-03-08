import Combine
import MapKit
import SwiftUI

struct MapPickerView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (TransitStop) -> Void

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var stops: [TransitStop] = []
    @State private var selectedStop: TransitStop?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: stops) { stop in
                MapAnnotation(coordinate: stop.coordinate.clLocation) {
                    Button {
                        selectedStop = stop
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "bus.fill")
                                .foregroundColor(selectedStop?.id == stop.id ? .red : .blue)
                                .font(.title3)
                            Text(stop.name)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .onAppear {
                appState.locationService.requestPermissionAndStart()
                if let location = appState.locationService.currentLocation {
                    region.center = location
                    loadStops(around: location)
                }
            }
            .onReceive(appState.locationService.$currentLocation.compactMap { $0 }) { location in
                region.center = location
                if stops.isEmpty {
                    loadStops(around: location)
                }
            }

            if let selectedStop {
                Button {
                    onSelect(selectedStop)
                } label: {
                    Label("\(selectedStop.name) 선택", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding()
                }
            }
        }
    }

    private func loadStops(around location: CLLocationCoordinate2D) {
        Task {
            let fetched = (try? await appState.transitService.nearbyStops(location: location)) ?? []
            await MainActor.run {
                stops = fetched
            }
        }
    }
}
