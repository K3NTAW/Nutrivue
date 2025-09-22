import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \Meal.date) private var meals: [Meal]
    @Query private var users: [User]
    @Query private var recipes: [Recipe]
    
    @State private var showingScannerSheet = false
    // Use item-bound sheets to avoid race where content evaluates with nil meal on first presentation
    @State private var mealForSearch: Meal?
    @State private var mealForAdd: Meal?
    @State private var showingMealPicker = false
    @State private var showingGlobalMealPicker = false
    @State private var mealForGlobalAdd: Meal?
    @State private var showingAddTypeDialog = false
    @State private var showingRecipePicker = false
    @State private var selectedRecipe: Recipe?
    @State private var mealForRecipe: Meal?
    @State private var adjustingItemContext: AdjustItemContext?
    @State private var adjustingRecipeContext: AdjustRecipeContext?
    
    @StateObject private var foodLookupViewModel = FoodLookupViewModel()
    @StateObject private var foodSearchViewModel = SearchViewModel()
    
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    
    var body: some View {
        NavigationView {
            mealsList
            .listStyle(.insetGrouped)
            .navigationTitle("Log")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingGlobalMealPicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                    Button(action: {
                        showingScannerSheet = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(item: $mealForSearch, onDismiss: {
                // Reset search state when the sheet is closed
                foodSearchViewModel.searchResults = []
                foodSearchViewModel.searchQuery = ""
            }) { meal in
                FoodSearchView(viewModel: foodSearchViewModel, meal: meal)
            }
            .sheet(item: $mealForAdd, onDismiss: {
                resetScanState()
            }) { meal in
                AddFoodView(meal: meal, product: foodLookupViewModel.product)
            }
            .sheet(isPresented: $showingScannerSheet) {
                BarcodeScannerView { barcode in
                    // This closure is called when a barcode is successfully scanned.
                    
                    // Add haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    // Dismiss the scanner
                    showingScannerSheet = false
                    
                    // Start the product lookup
                    foodLookupViewModel.fetchProduct(barcode: barcode)
                }
            }
            .onChange(of: foodLookupViewModel.product) {
                if foodLookupViewModel.product != nil {
                    // Product loaded from scan → ask user which meal to add to
                    showingMealPicker = true
                }
            }
            .confirmationDialog("Choose Meal", isPresented: $showingMealPicker, titleVisibility: .visible) {
                ForEach(todaysMeals) { meal in
                    Button(meal.name) {
                        mealForAdd = meal
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Product Not Found", isPresented: $foodLookupViewModel.productNotFound) {
                Button("Add Manually") {
                    // Ask for meal even for manual entry
                    showingMealPicker = true
                    foodLookupViewModel.product = nil // Ensure we are in manual mode
                }
                Button("OK", role: .cancel) {
                    resetScanState()
                }
            }
            .confirmationDialog("Choose Meal", isPresented: $showingGlobalMealPicker, titleVisibility: .visible) {
                ForEach(todaysMeals) { meal in
                    Button(meal.name) {
                        mealForGlobalAdd = meal
                        showingAddTypeDialog = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Add to \(mealForGlobalAdd?.name ?? "Meal")", isPresented: $showingAddTypeDialog, titleVisibility: .visible) {
                Button("Add Food") {
                    if let meal = mealForGlobalAdd {
                        mealForSearch = meal
                    }
                    mealForGlobalAdd = nil
                }
                Button("Add Recipe") {
                    if let meal = mealForGlobalAdd {
                        mealForRecipe = meal
                        showingRecipePicker = true
                    }
                    mealForGlobalAdd = nil
                }
                Button("Cancel", role: .cancel) { mealForGlobalAdd = nil }
            }
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerView(onPick: { recipe in
                    selectedRecipe = recipe
                }, onCancel: {
                    selectedRecipe = nil
                })
            }
            .sheet(item: $selectedRecipe) { recipe in
                AdjustRecipeServingsView(recipe: recipe, defaultServings: recipe.servings) { servings in
                    if let targetMeal = mealForRecipe {
                        let n = recipe.scaledNutrition(servings: servings)
                        // Compute grams used based on total ingredient grams and servings
                        let totalGrams = recipe.ingredients.reduce(0.0) { $0 + $1.amountGrams }
                        let gramsPerServing = totalGrams / max(recipe.servings, 1)
                        let gramsUsed = gramsPerServing * servings
                        let item = FoodItem(
                            name: recipe.name,
                            calories: n.cal,
                            protein: n.p,
                            carbohydrates: n.c,
                            fat: n.f,
                            servingGrams: gramsUsed,
                            sourceRecipeId: recipe.id,
                            recipeServingsUsed: servings
                        )
                        targetMeal.items.append(item)
                        // Write widget snapshot after logging a recipe
                        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
                            WidgetSnapshotService(modelContainer: container).writeSnapshot()
                        }
                    }
                    mealForRecipe = nil
                }
            }
            .alert("Error", isPresented: .constant(foodLookupViewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    resetScanState()
                    foodLookupViewModel.errorMessage = nil
                }
            }, message: {
                Text(foodLookupViewModel.errorMessage ?? "An unknown error occurred.")
            })
            .overlay {
                if foodLookupViewModel.isLoading {
                    ZStack {
                        Color(white: 0, opacity: 0.75)
                            .ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text("Searching...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
                }
            }
        }
        // Sheets for adjusting items/recipes, attached to the main view instead of nested in overlay
        .sheet(item: $adjustingItemContext, content: { ctx in
            AdjustServingSheet(
                productName: ctx.item.name,
                caloriesPer100g: ctx.item.calories > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.calories / (ctx.item.servingGrams ?? 100)) * 100 : 0,
                proteinPer100g: ctx.item.protein > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.protein / (ctx.item.servingGrams ?? 100)) * 100 : 0,
                carbsPer100g: ctx.item.carbohydrates > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.carbohydrates / (ctx.item.servingGrams ?? 100)) * 100 : 0,
                fatPer100g: ctx.item.fat > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.fat / (ctx.item.servingGrams ?? 100)) * 100 : 0,
                initialGrams: ctx.item.servingGrams,
                onConfirm: { newGrams in
                    let per100Cal = ctx.item.calories > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.calories / (ctx.item.servingGrams ?? 100)) * 100 : 0
                    let per100P = ctx.item.protein > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.protein / (ctx.item.servingGrams ?? 100)) * 100 : 0
                    let per100C = ctx.item.carbohydrates > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.carbohydrates / (ctx.item.servingGrams ?? 100)) * 100 : 0
                    let per100F = ctx.item.fat > 0 && (ctx.item.servingGrams ?? 0) > 0 ? (ctx.item.fat / (ctx.item.servingGrams ?? 100)) * 100 : 0
                    ctx.item.calories = (per100Cal / 100) * newGrams
                    ctx.item.protein = (per100P / 100) * newGrams
                    ctx.item.carbohydrates = (per100C / 100) * newGrams
                    ctx.item.fat = (per100F / 100) * newGrams
                    ctx.item.servingGrams = newGrams
                    if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
                        WidgetSnapshotService(modelContainer: container).writeSnapshot()
                    }
                    adjustingItemContext = nil
                },
                onCancel: {
                    adjustingItemContext = nil
                }
            )
        })
        .sheet(item: $adjustingRecipeContext, content: { ctx in
            AdjustRecipeServingsView(recipe: ctx.recipe, defaultServings: ctx.item.recipeServingsUsed ?? ctx.recipe.servings) { newServings in
                let n = ctx.recipe.scaledNutrition(servings: newServings)
                let totalGrams = ctx.recipe.ingredients.reduce(0.0) { $0 + $1.amountGrams }
                let gramsPerServing = totalGrams / max(ctx.recipe.servings, 1)
                let gramsUsed = gramsPerServing * newServings
                ctx.item.calories = n.cal
                ctx.item.protein = n.p
                ctx.item.carbohydrates = n.c
                ctx.item.fat = n.f
                ctx.item.servingGrams = gramsUsed
                ctx.item.recipeServingsUsed = newServings
                if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
                    WidgetSnapshotService(modelContainer: container).writeSnapshot()
                }
                adjustingRecipeContext = nil
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .quickAddFood)) { _ in
            showingGlobalMealPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickAddRecipe)) { _ in
            showingGlobalMealPicker = true
            showingAddTypeDialog = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickScan)) { _ in
            showingScannerSheet = true
        }
    }
    
    private var mealsList: some View {
        List {
            ForEach(todaysMeals) { meal in
                MealSectionView(
                    meal: meal,
                    unitSystem: unitSystem,
                    onAddRecipe: {
                        mealForRecipe = meal
                        showingRecipePicker = true
                    },
                    onAddFood: {
                        mealForSearch = meal
                    },
                    onDeleteItems: { indexSet in
                        deleteFoodItem(from: meal, at: indexSet)
                    },
                    onTapItem: { item in presentAdjustServing(for: item, in: meal) }
                )
            }
        }
    }
    
    private func deleteFoodItem(from meal: Meal, at offsets: IndexSet) {
        meal.items.remove(atOffsets: offsets)
        // Write snapshot using a temporary container (no direct modelContext in this view)
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
    }
    
    private func resetScanState() {
        foodLookupViewModel.product = nil
        foodLookupViewModel.productNotFound = false
    }
    
    private func presentAdjustServing(for item: FoodItem, in meal: Meal) {
        if let rid = item.sourceRecipeId, let recipe = recipes.first(where: { $0.id == rid }) {
            adjustingRecipeContext = AdjustRecipeContext(meal: meal, item: item, recipe: recipe)
        } else {
            adjustingItemContext = AdjustItemContext(meal: meal, item: item)
        }
    }
    
}

private struct AdjustItemContext: Identifiable {
    let id = UUID()
    let meal: Meal
    let item: FoodItem
}

private struct AdjustRecipeContext: Identifiable {
    let id = UUID()
    let meal: Meal
    let item: FoodItem
    let recipe: Recipe
}

private struct FoodRow: View {
    @Query private var users: [User]
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    let item: FoodItem
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text(String(format: "%.0f kcal", item.calories))
                .foregroundColor(.secondary)
        }
    }
}

private struct MacroPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(.tertiarySystemFill)))
            .foregroundColor(.secondary)
    }
}

private struct MealSectionView: View {
    let meal: Meal
    let unitSystem: UnitSystem
    let onAddRecipe: () -> Void
    let onAddFood: () -> Void
    let onDeleteItems: (IndexSet) -> Void
    let onTapItem: (FoodItem) -> Void
    
    var body: some View {
        Section {
            ForEach(meal.items) { item in
                Button { onTapItem(item) } label: { FoodRow(item: item) }
                .buttonStyle(.plain)
            }
            .onDelete(perform: onDeleteItems)
        } header: {
            Text(meal.name)
        } footer: {
            MealFooter(
                meal: meal,
                unitSystem: unitSystem,
                onAddRecipe: onAddRecipe,
                onAddFood: onAddFood
            )
        }
    }
}

private struct MealFooter: View {
    let meal: Meal
    let unitSystem: UnitSystem
    let onAddRecipe: () -> Void
    let onAddFood: () -> Void
    
    var body: some View {
        EmptyView()
    }
}

// (Supplements removed from LogView)


#Preview {
    LogView()
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}


