import SwiftUI
import SwiftData
import WidgetKit

struct AddFoodView: View {
    @Query private var users: [User]
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meal: Meal
    let product: ProductData?
    
    // Form state
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSizeGrams = ""
    
    // Computed properties for calculated values
    private var inputServingAsGrams: Double {
        let raw = Double(servingSizeGrams) ?? 0
        switch unitSystem {
        case .metric: return raw
        case .imperial: return raw * 28.349523125 // oz -> g
        }
    }
    private var calculatedCalories: Double {
        let baseCalories = product?.nutriments?.energyKcal100g ?? Double(calories) ?? 0
        return (baseCalories / 100) * inputServingAsGrams
    }
    
    private var calculatedProtein: Double {
        let baseProtein = product?.nutriments?.proteins100g ?? Double(protein) ?? 0
        return (baseProtein / 100) * inputServingAsGrams
    }
    
    private var calculatedCarbs: Double {
        let baseCarbs = product?.nutriments?.carbohydrates100g ?? Double(carbs) ?? 0
        return (baseCarbs / 100) * inputServingAsGrams
    }
    
    private var calculatedFat: Double {
        let baseFat = product?.nutriments?.fat100g ?? Double(fat) ?? 0
        return (baseFat / 100) * inputServingAsGrams
    }
    
    var body: some View {
        NavigationView {
            Form {
                if product != nil {
                    // Search result flow
                    Section(header: Text("Confirm Nutrition")) {
                        Text(name)
                        HStack {
                            TextField("Serving size", text: $servingSizeGrams)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .accessibilityLabel(unitSystem == .metric ? "Serving size in grams" : "Serving size in ounces")
                            Spacer()
                            Text(unitSystem == .metric ? "g" : "oz").foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint(unitSystem == .metric ? "Tap to edit grams" : "Tap to edit ounces")
                    }
                    Section(header: Text("Calculated Nutrition")) {
                        Text("Calories: \(calculatedCalories, specifier: "%.0f") kcal")
                        Text("Protein: \(MassUnitFormatter.formatMacro(grams: calculatedProtein, unitSystem: unitSystem))")
                        Text("Carbohydrates: \(MassUnitFormatter.formatMacro(grams: calculatedCarbs, unitSystem: unitSystem))")
                        Text("Fat: \(MassUnitFormatter.formatMacro(grams: calculatedFat, unitSystem: unitSystem))")
                    }
                } else {
                    // Manual entry flow
                    Section {
                        TextField("Food Name", text: $name)
                        TextField("Calories per 100g", text: $calories)
                            .keyboardType(.numberPad)
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.decimalPad)
                        TextField("Carbohydrates (g)", text: $carbs)
                            .keyboardType(.decimalPad)
                        TextField("Fat (g)", text: $fat)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(product != nil ? "Adjust Serving" : "Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { saveFood() }
                        .disabled((product != nil) && ((Double(servingSizeGrams) ?? 0) <= 0))
                }
            }
            .onAppear(perform: prefillForm)
        }
    }
    
    private func prefillForm() {
        if let product = product {
            name = product.productName ?? ""
        }
    }
    
    private func saveFood() {
        let finalCalories = calculatedCalories
        let finalProtein = calculatedProtein
        let finalCarbs = calculatedCarbs
        let finalFat = calculatedFat
        
        let gramsUsed = inputServingAsGrams
        let newFood = FoodItem(name: name, calories: finalCalories, protein: finalProtein, carbohydrates: finalCarbs, fat: finalFat, servingGrams: gramsUsed > 0 ? gramsUsed : nil)
        meal.items.append(newFood)
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
        dismiss()
    }
}

#Preview {
    // We need to create a dummy meal for the preview to work.
    let meal = Meal(name: "Breakfast", items: [], date: Date())
    return AddFoodView(meal: meal, product: nil)
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}
