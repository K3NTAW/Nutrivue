import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let overflow: Double? // 0..1 of overflow to display in red
    let lineWidth: CGFloat = 20.0
    let size: CGFloat = 220
    
    var body: some View {
        ZStack {
            // Background ring with subtle gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
            
            // Main progress ring with gradient
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(DesignSystem.Animation.standard, value: progress)
            
            // Overflow ring in red
            if let overflow, overflow > 0 {
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(overflow, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.error.opacity(0.8), DesignSystem.Colors.error],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(DesignSystem.Animation.standard, value: overflow)
            }
            
            // Inner glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 3
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ProgressRingView(progress: 0.65, color: .blue, overflow: 0.2)
        .frame(width: 150, height: 150)
        .padding()
}
