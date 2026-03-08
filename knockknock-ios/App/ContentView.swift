import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isSearching {
                RadarView()
                    .navigationBarHidden(true)
            } else if appState.selectedStop != nil {
                ReadyView()
            } else {
                TransportPickerView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ReadyView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                if let stop = appState.selectedStop {
                    VStack(spacing: 8) {
                        Text("목적지")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stop.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                    }
                }

                Button {
                    appState.startSearching()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )

                        Text("SEARCH")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Button {
                    appState.selectedStop = nil
                } label: {
                    Text("← 다시 선택")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
