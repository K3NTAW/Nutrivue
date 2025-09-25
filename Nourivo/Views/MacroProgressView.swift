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
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                Spacer()
                Text("\(MassUnitFormatter.formatMacro(grams: current, unitSystem: unitSystem)) / \(MassUnitFormatter.formatMacro(grams: goal, unitSystem: unitSystem))")
            }
            .font(.caption)
            
            let barColor: Color = overflowAmount > 0 ? .red : color
            ProgressView(value: min(progress, 1))
                .progressViewStyle(LinearProgressViewStyle(tint: barColor))
            if overflowAmount > 0 {
                Text("Over by \(MassUnitFormatter.formatMacro(grams: overflowAmount, unitSystem: unitSystem))")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
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
