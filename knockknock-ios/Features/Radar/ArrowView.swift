import SwiftUI

struct ArrowView: View {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat = 28) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: 4)
    }
}

#Preview {
    ZStack {
        Color.black
        ArrowView(color: .red)
    }
}
