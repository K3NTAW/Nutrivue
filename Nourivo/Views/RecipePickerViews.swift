import SwiftUI
import SwiftData

struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]
    var onPick: (Recipe) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            List(recipes) { recipe in
                Button {
                    onPick(recipe)
                    dismiss()
                } label: {
                    HStack {
                        Text(recipe.name)
                        Spacer()
                        let per = recipe.perServingNutrition()
                        Text(String(format: "%.0f kcal/serv", per.cal)).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Pick Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onCancel(); dismiss() } }
            }
        }
    }
}

struct AdjustRecipeServingsView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var servings: Double
    var onConfirm: (Double) -> Void
    
    init(recipe: Recipe, defaultServings: Double, onConfirm: @escaping (Double) -> Void) {
        self.recipe = recipe
        _servings = State(initialValue: max(0.1, defaultServings))
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(recipe.name)) {
                    Stepper(value: $servings, in: 0.1...50, step: 0.5) {
                        Text("Servings: \(servings, specifier: "%.1f")")
                    }
                    let n = recipe.scaledNutrition(servings: servings)
                    Text(String(format: "%.0f kcal, P %.1f g, C %.1f g, F %.1f g", n.cal, n.p, n.c, n.f))
                }
            }
            .navigationTitle("Adjust Servings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { onConfirm(servings); dismiss() }
                }
            }
        }
    }
}


