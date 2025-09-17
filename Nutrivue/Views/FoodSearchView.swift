import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: FoodSearchViewModel
    @State private var showingAddFoodManually = false
    @State private var selectedProduct: ProductData?
    
    let meal: Meal
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                
                List(viewModel.searchResults) { product in
                    Button(action: {
                        selectedProduct = product
                    }) {
                        Text(product.productName ?? "Unknown Food")
                    }
                }
            }
            .navigationTitle("Search Food")
            .searchable(text: $viewModel.searchQuery)
            .onSubmit(of: .search) {
                viewModel.performSearch(query: viewModel.searchQuery)
            }
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
            .sheet(item: $selectedProduct) { product in
                AddFoodView(meal: meal, product: product)
            }
            .onAppear {
                viewModel.activate()
            }
        }
    }
}
