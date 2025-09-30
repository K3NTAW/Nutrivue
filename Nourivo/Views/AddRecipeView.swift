import SwiftUI
import SwiftData
import WidgetKit

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var servings: Double = 1
    @State private var ingredients: [RecipeIngredient] = []
    @State private var showingSearch = false
    @State private var selectedProduct: ProductData?
    @State private var showingScanner = false
    @State private var scannedProduct: ProductData?
    @State private var scanGramsText: String = "100"
    @StateObject private var foodLookupVM = FoodLookupViewModel()
    @StateObject private var searchVM = SearchViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.accent.opacity(0.2),
                                                DesignSystem.Colors.accent.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Create Recipe")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.5)
                                
                                Text("Build your own recipes with custom ingredients")
                                    .font(.system(size: 17, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .opacity(0.85)
                                    .kerning(0.1)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Recipe Details")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                RecipeInputField(title: "Recipe Name", text: $name, placeholder: "e.g., Chicken Stir Fry")
                                RecipeInputField(title: "Notes (optional)", text: $notes, placeholder: "e.g., Great for meal prep")
                                
                                // Servings Stepper
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Servings")
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.2)
                                    
                                    HStack {
                    Stepper(value: $servings, in: 0.1...50, step: 0.5) {
                                            Text("\(String(format: "%.1f", servings)) servings")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.adaptiveSurface())
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Ingredients Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "list.bullet.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Ingredients")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                    if ingredients.isEmpty {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.1))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "fork.knife")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text("No ingredients yet")
                                                .font(.system(size: 16, weight: .semibold, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(0.2)
                                            
                                            Text("Add ingredients to build your recipe")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                                .opacity(0.8)
                                                .kerning(0.1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.5))
                                    )
                    } else {
                        ForEach(ingredients, id: \.id) { ing in
                            IngredientRow(ingredient: ing)
                        }
                        .onDelete { idx in
                            ingredients.remove(atOffsets: idx)
                        }
                    }
                                
                                // Add Ingredient Buttons
                                HStack(spacing: 12) {
                    Button {
                        showingSearch = true
                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Add Ingredient")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(DesignSystem.Colors.accent)
                                        )
                                    }
                                    
                    Button {
                        showingScanner = true
                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "barcode.viewfinder")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Scan")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(DesignSystem.Colors.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(DesignSystem.Colors.accent, lineWidth: 2)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Nutrition Summary
                        if !ingredients.isEmpty {
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
                                    
                                    Text("Nutrition Summary")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                // Nutrition Cards
                                HStack(spacing: 12) {
                                    // Total Recipe Card
                                    VStack(spacing: 12) {
                                        HStack {
                                            Image(systemName: "fork.knife")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(DesignSystem.Colors.accent)
                                            
                                            Text("Total Recipe")
                                                .font(.system(size: 14, weight: .semibold, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(0.2)
                                            
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            let totalNutrition = getTotalNutrition()
                                            HStack {
                                                Text("\(String(format: "%.0f", totalNutrition.cal))")
                                                    .font(.system(size: 20, weight: .bold, design: .default))
                                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                    .kerning(-0.5)
                                                
                                                Text("kcal")
                                                    .font(.system(size: 12, weight: .medium, design: .default))
                                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                                    .kerning(0.3)
                                                
                                                Spacer()
                                            }
                                            
                                            HStack(spacing: 16) {
                                                MacroItem(name: "P", value: totalNutrition.p, unit: "g", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                                MacroItem(name: "C", value: totalNutrition.c, unit: "g", color: Color(red: 0.3, green: 1.0, blue: 0.5))
                                                MacroItem(name: "F", value: totalNutrition.f, unit: "g", color: Color(red: 1.0, green: 0.7, blue: 0.2))
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
                                    
                                    // Per Serving Card
                                    VStack(spacing: 12) {
                                        HStack {
                                            Image(systemName: "person.2")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(DesignSystem.Colors.accent)
                                            
                                            Text("Per Serving")
                                                .font(.system(size: 14, weight: .semibold, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(0.2)
                                            
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            let perServingNutrition = getPerServingNutrition()
                                            HStack {
                                                Text("\(String(format: "%.0f", perServingNutrition.cal))")
                                                    .font(.system(size: 20, weight: .bold, design: .default))
                                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                    .kerning(-0.5)
                                                
                                                Text("kcal")
                                                    .font(.system(size: 12, weight: .medium, design: .default))
                                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                                    .kerning(0.3)
                                                
                                                Spacer()
                                            }
                                            
                                            HStack(spacing: 16) {
                                                MacroItem(name: "P", value: perServingNutrition.p, unit: "g", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                                MacroItem(name: "C", value: perServingNutrition.c, unit: "g", color: Color(red: 0.3, green: 1.0, blue: 0.5))
                                                MacroItem(name: "F", value: perServingNutrition.f, unit: "g", color: Color(red: 1.0, green: 0.7, blue: 0.2))
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
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Save Button
                        Button(action: {
                            save()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Create Recipe")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(
                                        color: DesignSystem.Colors.accent.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || ingredients.isEmpty || servings <= 0)
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || ingredients.isEmpty || servings <= 0)
                }
            }
            .sheet(isPresented: $showingSearch) {
                IngredientSearchView(searchVM: searchVM) { product, grams in
                    if let nutr = product.nutriments {
                        let ing = RecipeIngredient(
                            name: product.productName ?? "Ingredient",
                            amountGrams: grams,
                            caloriesPer100g: nutr.energyKcal100g ?? 0,
                            proteinPer100g: nutr.proteins100g ?? 0,
                            carbsPer100g: nutr.carbohydrates100g ?? 0,
                            fatPer100g: nutr.fat100g ?? 0,
                            sourceBarcode: product.code,
                            sourceImageUrl: product.imageUrl
                        )
                        ingredients.append(ing)
                    }
                    showingSearch = false
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { barcode in
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showingScanner = false
                    foodLookupVM.fetchProduct(barcode: barcode)
                }
            }
            .sheet(item: $scannedProduct) { product in
                AdjustServingSheet(productName: product.productName ?? "Ingredient",
                                    caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
                                    proteinPer100g: product.nutriments?.proteins100g ?? 0,
                                    carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
                                    fatPer100g: product.nutriments?.fat100g ?? 0,
                                    onConfirm: { grams in
                    let ing = RecipeIngredient(
                        name: product.productName ?? "Ingredient",
                        amountGrams: grams,
                        caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
                        proteinPer100g: product.nutriments?.proteins100g ?? 0,
                        carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
                        fatPer100g: product.nutriments?.fat100g ?? 0,
                        sourceBarcode: product.code,
                        sourceImageUrl: product.imageUrl
                    )
                    ingredients.append(ing)
                    foodLookupVM.product = nil
                    scannedProduct = nil
                }, onCancel: {
                    scannedProduct = nil
                })
            }
            .onChange(of: foodLookupVM.product) {
                if let p = foodLookupVM.product { scannedProduct = p }
            }
            .alert("Product Not Found", isPresented: $foodLookupVM.productNotFound) {
                Button("OK", role: .cancel) { resetScanState() }
            }
            .alert("Error", isPresented: .constant(foodLookupVM.errorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    resetScanState()
                    foodLookupVM.errorMessage = nil
                }
            }, message: {
                Text(foodLookupVM.errorMessage ?? "An unknown error occurred.")
            })
            .overlay {
                if foodLookupVM.isLoading {
                    ZStack {
                        Color(white: 0, opacity: 0.75).ignoresSafeArea()
                        VStack {
                            ProgressView().tint(.white)
                            Text("Searching...").foregroundColor(.white).padding(.top)
                        }
                    }
                }
            }
        }
    }
    
    private func getTotalNutrition() -> (cal: Double, p: Double, c: Double, f: Double) {
        let cal = ingredients.reduce(0) { $0 + $1.totals().cal }
        let p = ingredients.reduce(0) { $0 + $1.totals().p }
        let c = ingredients.reduce(0) { $0 + $1.totals().c }
        let f = ingredients.reduce(0) { $0 + $1.totals().f }
        return (cal: cal, p: p, c: c, f: f)
    }
    
    private func getPerServingNutrition() -> (cal: Double, p: Double, c: Double, f: Double) {
        let total = getTotalNutrition()
        let servingsCount = max(servings, 1)
        return (
            cal: total.cal / servingsCount,
            p: total.p / servingsCount,
            c: total.c / servingsCount,
            f: total.f / servingsCount
        )
    }
    
    private func totalsText() -> String {
        let unitSystem: UnitSystem = (try? modelContext.fetch(FetchDescriptor<User>()).first?.unitSystem) ?? .metric
        let cal = ingredients.reduce(0) { $0 + $1.totals().cal }
        let p = ingredients.reduce(0) { $0 + $1.totals().p }
        let c = ingredients.reduce(0) { $0 + $1.totals().c }
        let f = ingredients.reduce(0) { $0 + $1.totals().f }
        return "\(String(format: "%.0f", cal)) kcal, P \(MassUnitFormatter.formatMacro(grams: p, unitSystem: unitSystem)), C \(MassUnitFormatter.formatMacro(grams: c, unitSystem: unitSystem)), F \(MassUnitFormatter.formatMacro(grams: f, unitSystem: unitSystem))"
    }
    
    private func perServingText() -> String {
        let unitSystem: UnitSystem = (try? modelContext.fetch(FetchDescriptor<User>()).first?.unitSystem) ?? .metric
        let cal = ingredients.reduce(0) { $0 + $1.totals().cal } / max(servings, 1)
        let p = ingredients.reduce(0) { $0 + $1.totals().p } / max(servings, 1)
        let c = ingredients.reduce(0) { $0 + $1.totals().c } / max(servings, 1)
        let f = ingredients.reduce(0) { $0 + $1.totals().f } / max(servings, 1)
        return "\(String(format: "%.0f", cal)) kcal, P \(MassUnitFormatter.formatMacro(grams: p, unitSystem: unitSystem)), C \(MassUnitFormatter.formatMacro(grams: c, unitSystem: unitSystem)), F \(MassUnitFormatter.formatMacro(grams: f, unitSystem: unitSystem))"
    }
    
    private func save() {
        let recipe = Recipe(name: name.trimmingCharacters(in: .whitespacesAndNewlines), notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes, servings: servings, ingredients: ingredients)
        modelContext.insert(recipe)
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
        dismiss()
    }
    
    private func resetScanState() {
        foodLookupVM.product = nil
        foodLookupVM.productNotFound = false
    }
}

private struct IngredientRow: View {
    let ingredient: RecipeIngredient
    var body: some View {
        HStack(spacing: 12) {
            // Ingredient Image
            if let url = URL(string: ingredient.sourceImageUrl ?? "") {
                AsyncImage(url: url) { image in 
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: { 
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.adaptiveSurface())
                        
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                    }
                }
                .frame(width: 48, height: 48)
                .clipped()
                .cornerRadius(8)
            } else {
                ZStack { 
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.adaptiveSurface())
                    
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                }
                .frame(width: 48, height: 48)
            }
            
            // Ingredient Info
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.1)
                    .lineLimit(2)
                
                Text(String(format: "%.0f g", ingredient.amountGrams))
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.2)
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing, spacing: 2) {
            let t = ingredient.totals()
                Text(String(format: "%.0f", t.cal))
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(-0.3)
                
                Text("kcal")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.adaptiveSurface())
        )
    }
}

private struct IngredientSearchView: View {
    @ObservedObject var searchVM: SearchViewModel
    var onPick: (ProductData, Double) -> Void
    @State private var gramsText: String = "100"
    @State private var pickedProduct: ProductData?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Search and add ingredients to your recipe")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .opacity(0.85)
                                .kerning(0.1)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        
                        // Search Results
                        VStack(spacing: 16) {
                            // Favorites Section
                    if !searchVM.favorites.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        
                                        Text("Favorites")
                                            .font(.system(size: 18, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.3)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    LazyVStack(spacing: 8) {
                            ForEach(searchVM.favorites) { product in
                                Button(action: {
                                    pickedProduct = product
                                    searchVM.recordSelection(product)
                                }) {
                                                IngredientSearchRow(product: product, query: searchVM.searchQuery, isFavorite: true) {
                                        searchVM.toggleFavorite(product)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                                    }
                                    .padding(.horizontal, 24)
                        }
                    }
                            
                            // Recent Searches Section
                    if !searchVM.recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        
                            Text("Recent Searches")
                                            .font(.system(size: 18, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.3)
                                        
                            Spacer()
                                        
                            Button("Clear") {
                                searchVM.clearRecents()
                            }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    LazyVStack(spacing: 8) {
                            ForEach(searchVM.recentSearches) { product in
                                Button(action: {
                                    pickedProduct = product
                                    searchVM.recordSelection(product)
                                }) {
                                                IngredientSearchRow(product: product, query: searchVM.searchQuery, isFavorite: searchVM.isFavorite(product)) {
                                        searchVM.toggleFavorite(product)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                            // Search Results Section
                            if !searchVM.searchResults.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        
                                        Text("Search Results")
                                            .font(.system(size: 18, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.3)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    LazyVStack(spacing: 8) {
                    ForEach(searchVM.searchResults) { product in
                        Button {
                            pickedProduct = product
                        } label: {
                                                IngredientSearchRow(product: product, query: searchVM.searchQuery, isFavorite: searchVM.isFavorite(product)) {
                                                    searchVM.toggleFavorite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                            // Empty States
                    if searchVM.searchQuery.isEmpty && searchVM.searchResults.isEmpty && searchVM.recentSearches.isEmpty {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Search for Ingredients")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.2)
                                        
                                        Text("Find ingredients to add to your recipe")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .opacity(0.8)
                                            .kerning(0.1)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .padding(.horizontal, 24)
                    } else if !searchVM.searchQuery.isEmpty && searchVM.searchResults.isEmpty {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("No Results")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.2)
                                        
                                        Text("No ingredients found for '\(searchVM.searchQuery)'")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .opacity(0.8)
                                            .kerning(0.1)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchVM.searchQuery)
            .onAppear { searchVM.activate() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Cancel") { dismiss() } 
                }
            }
            .sheet(item: $pickedProduct) { p in
                AdjustServingSheet(productName: p.productName ?? "Ingredient",
                                   caloriesPer100g: p.nutriments?.energyKcal100g ?? 0,
                                   proteinPer100g: p.nutriments?.proteins100g ?? 0,
                                   carbsPer100g: p.nutriments?.carbohydrates100g ?? 0,
                                   fatPer100g: p.nutriments?.fat100g ?? 0,
                                   onConfirm: { grams in
                    onPick(p, grams)
                    dismiss()
                }, onCancel: {
                    pickedProduct = nil
                })
            }
        }
    }
}

private struct IngredientSearchRow: View {
    let product: ProductData
    let query: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let url = URL(string: product.imageUrl ?? "") {
                AsyncImage(url: url) { image in 
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: { 
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.adaptiveSurface())
                        
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                    }
                }
                .frame(width: 48, height: 48)
                .clipped()
                .cornerRadius(8)
            } else {
                ZStack { 
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.adaptiveSurface())
                    
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                }
                .frame(width: 48, height: 48)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName ?? "Item")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.1)
                    .lineLimit(2)
                
                Text("Ingredient")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.2)
            }
            
            Spacer()
            
            // Favorite Button
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFavorite ? DesignSystem.Colors.accent : DesignSystem.Colors.adaptiveTertiaryText())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.adaptiveSurface())
        )
    }
}

// MARK: - Helper Views
private struct RecipeInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                .kerning(0.2)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Colors.adaptiveSurface())
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConditionalSearchable: ViewModifier {
    @Binding var searchQuery: String
    let showSearch: Bool
    
    func body(content: Content) -> some View {
        if showSearch {
            content.searchable(text: $searchQuery)
        } else {
            content
        }
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



