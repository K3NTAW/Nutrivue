import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt) private var recipes: [Recipe]
    @State private var showingAdd = false
    @State private var searchQuery = ""
    @State private var selectedRecipe: Recipe?
    
    private var filteredRecipes: [Recipe] {
        if searchQuery.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recipes")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.5)
                                
                                Text("Your personal recipe collection")
                                    .font(.system(size: 17, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .opacity(0.85)
                                    .kerning(0.1)
                            }
                            
                            Spacer()
                            
                            // Add Recipe Button
                            Button {
                                showingAdd = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 24)
                    
                    // Recipes List
                    if recipes.isEmpty {
                        // Empty State - Centered
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No Recipes Yet")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.2)
                                    
                                    Text("Create your first recipe to get started")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .opacity(0.8)
                                        .kerning(0.1)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button {
                                    showingAdd = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Create Recipe")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignSystem.Colors.accent)
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredRecipes.isEmpty && !searchQuery.isEmpty {
                        // No Search Results
                        VStack(spacing: 24) {
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
                                
                                Text("No recipes found for '\(searchQuery)'")
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
                    } else {
                        // Recipes List
                        List {
                            ForEach(filteredRecipes) { recipe in
                                Button(action: {
                                    selectedRecipe = recipe
                                }) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteRecipe(recipe)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchQuery)
            .sheet(isPresented: $showingAdd) { AddRecipeView() }
            .sheet(item: $selectedRecipe) { recipe in
                EditRecipeView(recipe: recipe)
            }
        }
    }
}

// MARK: - Helper Views
private struct RecipeCard: View {
    let recipe: Recipe
    
    private var perServingNutrition: (cal: Double, p: Double, c: Double, f: Double) {
        recipe.perServingNutrition()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Recipe Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
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
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .frame(width: 56, height: 56)
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.2)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    if recipe.servings > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            
                            Text("\(String(format: "%.1f", recipe.servings)) servings")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .kerning(0.1)
                        }
                    }
                    
                    if !recipe.ingredients.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            
                            Text("\(recipe.ingredients.count) ingredients")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .kerning(0.1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Nutrition Info
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.0f", perServingNutrition.cal))")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(-0.5)
                
                Text("kcal")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.3)
                
                Text("per serving")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                    .opacity(0.8)
                    .kerning(0.2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
}

private struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]
    @State private var name: String
    @State private var notes: String
    @State private var servings: Double
    @State private var ingredients: [RecipeIngredient]
    let recipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name)
        _notes = State(initialValue: recipe.notes ?? "")
        _servings = State(initialValue: recipe.servings)
        _ingredients = State(initialValue: recipe.ingredients)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("Edit Recipe")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                .kerning(-0.5)
                            
                            Text("Update your recipe details")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .opacity(0.85)
                                .kerning(0.1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Recipe Details")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                // Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recipe Name")
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.2)
                                    
                                    TextField("Enter recipe name", text: $name)
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(DesignSystem.Colors.adaptiveSurface())
                                        )
                                }
                                
                                // Notes Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes (Optional)")
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.2)
                                    
                                    TextField("Add notes...", text: $notes, axis: .vertical)
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(DesignSystem.Colors.adaptiveSurface())
                                        )
                                        .lineLimit(3...6)
                                }
                                
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
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignSystem.Colors.adaptiveSurface())
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Ingredients Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "list.bullet.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Ingredients")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 8) {
                                ForEach(ingredients, id: \.id) { ing in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        
                                        Text(ing.name)
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.1)
                                        
                                        Spacer()
                                        
                                        let unitSystem: UnitSystem = users.first?.unitSystem ?? .metric
                                        let isImp = unitSystem == .imperial
                                        let unit = isImp ? "oz" : "g"
                                        let display = isImp ? (ing.amountGrams / 28.349523125) : ing.amountGrams
                                        
                                        Text(String(format: "%.0f %@", display, unit))
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .kerning(0.2)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignSystem.Colors.adaptiveSurface())
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Cancel") { dismiss() } 
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        recipe.name = name
                        recipe.notes = notes.isEmpty ? nil : notes
                        recipe.servings = servings
                        recipe.ingredients = ingredients
                        recipe.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
    }
}


