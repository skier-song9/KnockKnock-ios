import SwiftUI

struct UserLabelView: View {
    let user: NearbyUser
    @State private var isBlinking = false

    var body: some View {
        VStack(spacing: 2) {
            if user.rank == 1 {
                Image(systemName: "star.fill")
                    .foregroundColor(user.sensorColor)
                    .font(.caption2)
            }

            Text(user.destinationStopName)
                .font(.system(size: user.fontSize, weight: user.rank == 1 ? .bold : .regular))
                .foregroundColor(.white)
                .opacity(user.rank == 1 ? (isBlinking ? 0.4 : 1.0) : user.labelOpacity)

            Text("[\(user.remainingStops)정류장]")
                .font(.system(size: user.fontSize - 3))
                .foregroundColor(user.sensorColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(user.rank == 1 ? user.sensorColor : Color.clear, lineWidth: 1)
                )
        )
        .onAppear {
            guard user.rank == 1 else { return }
            withAnimation(.easeInOut(duration: user.pulseSpeed).repeatForever()) {
                isBlinking = true
            }
        }
    }
}
