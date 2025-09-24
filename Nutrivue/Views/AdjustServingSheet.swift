import SwiftUI
import SwiftData

struct AdjustServingSheet: View {
    let productName: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    var initialGrams: Double? = nil
    var onConfirm: (Double) -> Void
    var onCancel: () -> Void
    
    @Query private var users: [User]
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    @State private var gramsText: String = ""
    
    private var inputAsGrams: Double {
        let raw = Double(gramsText) ?? 0
        switch unitSystem {
        case .metric: return raw
        case .imperial: return raw * 28.349523125
        }
    }
    private var calcCalories: Double { (caloriesPer100g / 100.0) * inputAsGrams }
    private var calcProtein: Double { (proteinPer100g / 100.0) * inputAsGrams }
    private var calcCarbs: Double { (carbsPer100g / 100.0) * inputAsGrams }
    private var calcFat: Double { (fatPer100g / 100.0) * inputAsGrams }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Confirm Nutrition")) {
                    Text(productName)
                    HStack {
                        TextField("Serving size", text: $gramsText)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .accessibilityLabel("Serving size in grams")
                        Spacer()
                        Text(unitSystem == .metric ? "g" : "oz").foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Tap to edit grams")
                }
                Section(header: Text("Calculated Nutrition")) {
                    Text("Calories: \(calcCalories, specifier: "%.0f") kcal")
                    Text("Protein: \(MassUnitFormatter.formatMacro(grams: calcProtein, unitSystem: unitSystem))")
                    Text("Carbohydrates: \(MassUnitFormatter.formatMacro(grams: calcCarbs, unitSystem: unitSystem))")
                    Text("Fat: \(MassUnitFormatter.formatMacro(grams: calcFat, unitSystem: unitSystem))")
                }
            }
            .navigationTitle("Adjust Serving")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { onConfirm(inputAsGrams) }
                        .disabled((Double(gramsText) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let g = initialGrams, gramsText.isEmpty {
                    let display = unitSystem == .metric ? g : (g / 28.349523125)
                    gramsText = String(format: display.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", display)
                }
            }
        }
    }
}
