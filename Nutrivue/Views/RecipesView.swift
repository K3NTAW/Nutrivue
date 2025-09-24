import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt) private var recipes: [Recipe]
    @State private var showingAdd = false
    @State private var searchQuery = ""
    
    private var filteredRecipes: [Recipe] {
        if searchQuery.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(destination: EditRecipeView(recipe: recipe)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                if recipe.servings > 0 {
                                    Text(String(format: "%.1f servings", recipe.servings)).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            let per = recipe.perServingNutrition()
                            Text(String(format: "%.0f kcal/serv", per.cal)).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    for i in idx { modelContext.delete(recipes[i]) }
                }
                if recipes.isEmpty {
                    VStack(spacing: 12) {
                        ContentUnavailableView("No Recipes", systemImage: "fork.knife", description: Text("Tap + to add a recipe."))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                } else if filteredRecipes.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView.search(text: searchQuery)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchQuery)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { AddRecipeView() }
        }
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
        Form {
            Section(header: Text("Details")) {
                TextField("Recipe name", text: $name)
                TextField("Notes (optional)", text: $notes)
                Stepper(value: $servings, in: 0.1...50, step: 0.5) {
                    Text("Servings: \(servings, specifier: "%.1f")")
                }
            }
            Section(header: Text("Ingredients")) {
                ForEach(ingredients, id: \.id) { ing in
                    HStack {
                        Text(ing.name)
                        Spacer()
                        let unitSystem: UnitSystem = users.first?.unitSystem ?? .metric
                        let isImp = unitSystem == .imperial
                        let unit = isImp ? "oz" : "g"
                        let display = isImp ? (ing.amountGrams / 28.349523125) : ing.amountGrams
                        Text(String(format: "%.0f %@", display, unit)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Recipe")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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


