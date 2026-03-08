import SwiftUI

struct SensorWidget: View {
    let color: Color
    let pulseSpeed: Double
    let arrowAngle: Double

    @State private var isPulsing = false
    @State private var outerScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .scaleEffect(outerScale)
                .opacity(isPulsing ? 0 : 0.8)
                .animation(
                    .easeOut(duration: pulseSpeed).repeatForever(autoreverses: false),
                    value: outerScale
                )

            Circle()
                .stroke(color.opacity(0.5), lineWidth: 1.5)
                .frame(width: 110, height: 110)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.8), color.opacity(0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 90, height: 90)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                )

            ArrowView(color: color)
                .rotationEffect(.degrees(arrowAngle))
                .animation(.easeInOut(duration: 0.3), value: arrowAngle)
        }
        .frame(width: 140, height: 140)
        .onAppear {
            startPulse()
        }
        .onChange(of: pulseSpeed) {
            startPulse()
        }
    }

    private func startPulse() {
        isPulsing = false
        outerScale = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: pulseSpeed).repeatForever(autoreverses: false)) {
                outerScale = 1.8
                isPulsing = true
            }
        }
    }
}
