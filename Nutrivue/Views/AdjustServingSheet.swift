import SwiftUI

struct AdjustServingSheet: View {
    let productName: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    var onConfirm: (Double) -> Void
    var onCancel: () -> Void
    
    @State private var gramsText: String = ""
    
    private var grams: Double { Double(gramsText) ?? 0 }
    private var calcCalories: Double { (caloriesPer100g / 100.0) * grams }
    private var calcProtein: Double { (proteinPer100g / 100.0) * grams }
    private var calcCarbs: Double { (carbsPer100g / 100.0) * grams }
    private var calcFat: Double { (fatPer100g / 100.0) * grams }
    
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
                        Text("g").foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Tap to edit grams")
                }
                Section(header: Text("Calculated Nutrition")) {
                    Text("Calories: \(calcCalories, specifier: "%.0f") kcal")
                    Text("Protein: \(calcProtein, specifier: "%.1f") g")
                    Text("Carbohydrates: \(calcCarbs, specifier: "%.1f") g")
                    Text("Fat: \(calcFat, specifier: "%.1f") g")
                }
            }
            .navigationTitle("Adjust Serving")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { onConfirm(grams) }
                        .disabled(grams <= 0)
                }
            }
        }
    }
}
