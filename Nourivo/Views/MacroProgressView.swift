import SwiftUI
import SwiftData

struct MacroProgressView: View {
    let name: String
    let current: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return current / goal
    }
    
    private var overflowAmount: Double {
        guard goal > 0 else { return 0 }
        return max(0, current - goal)
    }
    
    @Query private var users: [User]
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header with macro name and values
            HStack {
                Text(name)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(MassUnitFormatter.formatMacro(grams: current, unitSystem: unitSystem))")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    
                    Text("of \(MassUnitFormatter.formatMacro(grams: goal, unitSystem: unitSystem))")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                }
            }
            
            // Progress bar with gradient
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.adaptiveSurface())
                    .frame(height: 8)
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(
                        LinearGradient(
                            colors: overflowAmount > 0 ? 
                                [DesignSystem.Colors.error.opacity(0.8), DesignSystem.Colors.error] :
                                [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(min(progress, 1)) * UIScreen.main.bounds.width * 0.7, height: 8)
                    .animation(DesignSystem.Animation.standard, value: progress)
                
                // Overflow indicator
                if overflowAmount > 0 {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(DesignSystem.Colors.error)
                        .frame(width: min(CGFloat(overflowAmount) * UIScreen.main.bounds.width * 0.7, UIScreen.main.bounds.width * 0.7), height: 8)
                        .animation(DesignSystem.Animation.standard, value: overflowAmount)
                }
            }
            
            // Overflow text
            if overflowAmount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text("Over by \(MassUnitFormatter.formatMacro(grams: overflowAmount, unitSystem: unitSystem))")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Spacer()
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .metricCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue(accessibilityValueText)
    }
    
    private var accessibilityValueText: String {
        let base = "\(MassUnitFormatter.formatMacro(grams: current, unitSystem: unitSystem)) of \(MassUnitFormatter.formatMacro(grams: goal, unitSystem: unitSystem))"
        if overflowAmount > 0 {
            return base + ", over by \(MassUnitFormatter.formatMacro(grams: overflowAmount, unitSystem: unitSystem))"
        }
        return base
    }
}

#Preview {
    MacroProgressView(name: "Protein", current: 50, goal: 150, color: .red)
        .padding()
}
