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
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        if product != nil {
                            // Search result flow
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.accent)
                                        .font(.title3)
                                    
                                    Text("Confirm Nutrition")
                                        .font(DesignSystem.Typography.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    // Food Name
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Food Name")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        
                                        Text(name)
                                            .font(DesignSystem.Typography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.Spacing.md)
                                    .metricCardStyle()
                                    
                                    // Serving Size
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Serving Size")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        
                                        HStack {
                                            TextField("Enter amount", text: $servingSizeGrams)
                                                .keyboardType(.decimalPad)
                                                .textInputAutocapitalization(.never)
                                                .autocorrectionDisabled(true)
                                                .font(DesignSystem.Typography.subheadline)
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .accessibilityLabel(unitSystem == .metric ? "Serving size in grams" : "Serving size in ounces")
                                            
                                            Text(unitSystem == .metric ? "g" : "oz")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityHint(unitSystem == .metric ? "Tap to edit grams" : "Tap to edit ounces")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.Spacing.md)
                                    .metricCardStyle()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                            
                            // Calculated Nutrition
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "chart.bar.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    Text("Calculated Nutrition")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                // Nutrition Card
                                VStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        
                                        Text("Per Serving")
                                            .font(.system(size: 14, weight: .semibold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.2)
                                        
                                        Spacer()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("\(String(format: "%.0f", calculatedCalories))")
                                                .font(.system(size: 24, weight: .bold, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(-0.5)
                                            
                                            Text("kcal")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                                .kerning(0.3)
                                            
                                            Spacer()
                                        }
                                        
                                        HStack(spacing: 16) {
                                            MacroItem(name: "P", value: calculatedProtein, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                            MacroItem(name: "C", value: calculatedCarbs, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 0.3, green: 1.0, blue: 0.5))
                                            MacroItem(name: "F", value: calculatedFat, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 1.0, green: 0.7, blue: 0.2))
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(DesignSystem.Colors.adaptiveCardBackground())
                                        .shadow(
                                            color: .black.opacity(0.08),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                                .padding(.horizontal, 24)
                            }
                        } else {
                            // Manual entry flow
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.accent)
                                        .font(.title3)
                                    
                                    Text("Food Details")
                                        .font(DesignSystem.Typography.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    InputField(title: "Food Name", text: $name, placeholder: "Enter food name")
                                    InputField(title: "Calories per 100g", text: $calories, placeholder: "0", keyboardType: .numberPad)
                                    InputField(title: "Protein (g)", text: $protein, placeholder: "0.0", keyboardType: .decimalPad)
                                    InputField(title: "Carbohydrates (g)", text: $carbs, placeholder: "0.0", keyboardType: .decimalPad)
                                    InputField(title: "Fat (g)", text: $fat, placeholder: "0.0", keyboardType: .decimalPad)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                    .padding(.top, DesignSystem.Spacing.sm)
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

// MARK: - Helper Views
private struct NutritionRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .metricCardStyle()
    }
}

private struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .metricCardStyle()
    }
}

private struct MacroItem: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundColor(color)
                .kerning(0.5)
            
            Text("\(String(format: "%.1f", value))")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(-0.3)
            
            Text(unit)
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                .kerning(0.2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    // We need to create a dummy meal for the preview to work.
    let meal = Meal(name: "Breakfast", items: [], date: Date())
    return AddFoodView(meal: meal, product: nil)
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}
