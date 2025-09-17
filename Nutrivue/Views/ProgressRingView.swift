import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 20.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.65, color: .blue)
        .frame(width: 150, height: 150)
        .padding()
}
