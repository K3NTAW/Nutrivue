import SwiftUI

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let meal: Meal
    let product: ProductData?
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Food Name", text: $name)
                TextField("Calories", text: $calories)
                    .keyboardType(.numberPad)
                TextField("Protein (g)", text: $protein)
                    .keyboardType(.decimalPad)
                TextField("Carbohydrates (g)", text: $carbs)
                    .keyboardType(.decimalPad)
                TextField("Fat (g)", text: $fat)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveFood()
                    }
                }
            }
            .onAppear(perform: prefillForm)
        }
    }
    
    private func prefillForm() {
        guard let product = product else { return }
        
        name = product.productName ?? ""
        
        if let energy = product.nutriments?.energyKcal100g {
            calories = String(energy)
        }
        if let protein = product.nutriments?.proteins100g {
            self.protein = String(protein)
        }
        if let carbs = product.nutriments?.carbohydrates100g {
            self.carbs = String(carbs)
        }
        if let fat = product.nutriments?.fat100g {
            self.fat = String(fat)
        }
    }
    
    private func saveFood() {
        guard !name.isEmpty,
              let caloriesDouble = Double(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat) else {
            // Add user feedback for invalid input
            return
        }
        
        let newFood = FoodItem(name: name, calories: caloriesDouble, protein: proteinDouble, carbohydrates: carbsDouble, fat: fatDouble)
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
