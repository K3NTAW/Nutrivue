import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = FoodSearchViewModel()
    @State private var showingAddFoodManually = false
    
    let meal: Meal
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                
                List(viewModel.searchResults) { product in
                    Button(action: {
                        add(product: product)
                    }) {
                        Text(product.productName ?? "Unknown Food")
                    }
                }
            }
            .navigationTitle("Search Food")
            .searchable(text: $viewModel.searchQuery)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Manually") {
                        showingAddFoodManually = true
                    }
                }
            }
            .sheet(isPresented: $showingAddFoodManually) {
                AddFoodView(meal: meal, product: nil)
            }
        }
    }
    
    private func add(product: ProductData) {
        let foodItem = FoodItem(
            name: product.productName ?? "Unknown",
            calories: product.nutriments?.energyKcal100g ?? 0,
            protein: product.nutriments?.proteins100g ?? 0,
            carbohydrates: product.nutriments?.carbohydrates100g ?? 0,
            fat: product.nutriments?.fat100g ?? 0
        )
        meal.items.append(foodItem)
        dismiss()
    }
}
