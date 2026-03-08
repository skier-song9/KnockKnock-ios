import SwiftUI

struct TransportPickerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDestinationPicker = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("어떤 교통수단을 이용 중인가요?")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                TransportButton(type: .bus, selected: appState.transportType == .bus) {
                    appState.transportType = .bus
                }
                TransportButton(type: .subway, selected: appState.transportType == .subway) {
                    appState.transportType = .subway
                }
            }

            if appState.transportType != nil {
                Button {
                    showDestinationPicker = true
                } label: {
                    Text("목적지 선택 →")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                        .padding(.horizontal, 40)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut, value: appState.transportType)
            }

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showDestinationPicker) {
            DestinationPickerView(isPresented: $showDestinationPicker)
        }
        .onAppear {
            appState.locationService.requestPermissionAndStart()
        }
    }
}

struct TransportButton: View {
    let type: TransportType
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type == .bus ? "bus.fill" : "tram.fill")
                    .font(.system(size: 40))
                Text(type.displayName)
                    .font(.headline)
            }
            .frame(width: 120, height: 120)
            .background(selected ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(selected ? .black : .white)
            .cornerRadius(20)
        }
    }
}
