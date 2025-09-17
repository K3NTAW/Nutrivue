import SwiftUI

struct AddFoodView: View {
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
    @State private var servingSizeGrams = "100"
    
    // Computed properties for calculated values
    private var calculatedCalories: Double {
        let baseCalories = product?.nutriments?.energyKcal100g ?? Double(calories) ?? 0
        let serving = Double(servingSizeGrams) ?? 100
        return (baseCalories / 100) * serving
    }
    
    private var calculatedProtein: Double {
        let baseProtein = product?.nutriments?.proteins100g ?? Double(protein) ?? 0
        let serving = Double(servingSizeGrams) ?? 100
        return (baseProtein / 100) * serving
    }
    
    private var calculatedCarbs: Double {
        let baseCarbs = product?.nutriments?.carbohydrates100g ?? Double(carbs) ?? 0
        let serving = Double(servingSizeGrams) ?? 100
        return (baseCarbs / 100) * serving
    }
    
    private var calculatedFat: Double {
        let baseFat = product?.nutriments?.fat100g ?? Double(fat) ?? 0
        let serving = Double(servingSizeGrams) ?? 100
        return (baseFat / 100) * serving
    }
    
    var body: some View {
        NavigationView {
            Form {
                if product != nil {
                    // Search result flow
                    Section(header: Text("Confirm Nutrition")) {
                        Text(name)
                        TextField("Serving Size (g)", text: $servingSizeGrams)
                            .keyboardType(.decimalPad)
                    }
                    Section(header: Text("Calculated Nutrition")) {
                        Text("Calories: \(calculatedCalories, specifier: "%.0f") kcal")
                        Text("Protein: \(calculatedProtein, specifier: "%.1f") g")
                        Text("Carbohydrates: \(calculatedCarbs, specifier: "%.1f") g")
                        Text("Fat: \(calculatedFat, specifier: "%.1f") g")
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
        
        let newFood = FoodItem(name: name, calories: finalCalories, protein: finalProtein, carbohydrates: finalCarbs, fat: finalFat)
        meal.items.append(newFood)
        dismiss()
    }
}

#Preview {
    // We need to create a dummy meal for the preview to work.
    let meal = Meal(name: "Breakfast", items: [], date: Date())
    return AddFoodView(meal: meal, product: nil)
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}
