import SwiftUI

struct MacroProgressView: View {
    let name: String
    let current: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return current / goal
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                Spacer()
                Text("\(current, specifier: "%.1f")g / \(goal, specifier: "%.1f")g")
            }
            .font(.caption)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue("\(current, specifier: "%.1f") of \(goal, specifier: "%.1f") grams")
    }
}

#Preview {
    MacroProgressView(name: "Protein", current: 50, goal: 150, color: .red)
        .padding()
}
