import SwiftUI

struct RadarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDestinationPicker = false

    private let radarRadius: CGFloat = 140

    private var rank1User: NearbyUser? {
        appState.nearbyUsers.first(where: { $0.rank == 1 })
    }

    private var sensorColor: Color {
        rank1User?.sensorColor ?? .blue
    }

    private var pulseSpeed: Double {
        rank1User?.pulseSpeed ?? Constants.pulseDefault
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.95)
                    .ignoresSafeArea()

                radarGrid

                ForEach(appState.nearbyUsers.sorted(by: { $0.rank > $1.rank })) { user in
                    let position = labelPosition(for: user, in: geo.size)
                    UserLabelView(user: user)
                        .position(position)
                        .zIndex(user.zIndex)
                        .animation(.easeInOut(duration: 0.5), value: position)
                }

                SensorWidget(
                    color: sensorColor,
                    pulseSpeed: pulseSpeed,
                    arrowAngle: appState.arrowAngle
                )
                .position(x: geo.size.width / 2, y: geo.size.height / 2)

                if !appState.isUIHidden {
                    uiOverlay
                }
            }
            .onTapGesture {
                if appState.isUIHidden {
                    appState.isUIHidden = false
                }
            }
        }
    }

    private var radarGrid: some View {
        ZStack {
            ForEach([0.3, 0.6, 1.0], id: \.self) { scale in
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .scaleEffect(scale)
            }
        }
    }

    private var uiOverlay: some View {
        VStack {
            HStack {
                Button {
                    appState.isUIHidden = true
                } label: {
                    Image(systemName: "rectangle.compress.vertical")
                        .foregroundColor(.white.opacity(0.4))
                        .padding(12)
                }

                Spacer()

                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.white.opacity(0.4))
                        .padding(12)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            HStack {
                if let stop = appState.selectedStop {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                        Text(stop.name)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                Button {
                    showDestinationPicker = true
                } label: {
                    Text("변경")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showDestinationPicker) {
            DestinationPickerView(isPresented: $showDestinationPicker)
        }
    }

    private func labelPosition(for user: NearbyUser, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let angleRad = user.displayAngle * .pi / 180
        let radius = user.displayRadius.clamped(to: Double(radarRadius * 0.4)...Double(radarRadius * 1.2))

        return CGPoint(
            x: center.x + CGFloat(sin(angleRad)) * CGFloat(radius),
            y: center.y - CGFloat(cos(angleRad)) * CGFloat(radius)
        )
    }
}
