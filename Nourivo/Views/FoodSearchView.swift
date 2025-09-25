import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: SearchViewModel
    @State private var showingAddFoodManually = false
    @State private var selectedProduct: ProductData?
    
    let meal: Meal
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                List {
                    if !viewModel.favorites.isEmpty || !viewModel.recentSearches.isEmpty {
                        if !viewModel.favorites.isEmpty {
                            Section("Favorites") {
                                ForEach(viewModel.favorites) { product in
                                    Button(action: {
                                        selectedProduct = product
                                        viewModel.recordSelection(product)
                                    }) {
                                        SearchRow(product: product, query: viewModel.searchQuery, isFavorite: true) {
                                            viewModel.toggleFavorite(product)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        if !viewModel.recentSearches.isEmpty {
                            Section(header: HStack {
                                Text("Recent Searches")
                                Spacer()
                                Button("Clear") {
                                    viewModel.clearRecents()
                                }
                            }) {
                                ForEach(viewModel.recentSearches) { product in
                                    Button(action: {
                                        selectedProduct = product
                                        viewModel.recordSelection(product)
                                    }) {
                                        SearchRow(product: product, query: viewModel.searchQuery, isFavorite: viewModel.isFavorite(product)) {
                                            viewModel.toggleFavorite(product)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    ForEach(viewModel.searchResults) { product in
                        Button(action: {
                            selectedProduct = product
                            viewModel.recordSelection(product)
                        }) {
                            SearchRow(product: product, query: viewModel.searchQuery, isFavorite: viewModel.isFavorite(product)) {
                                viewModel.toggleFavorite(product)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .overlay {
                if viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty && viewModel.favorites.isEmpty && viewModel.recentSearches.isEmpty {
                    ContentUnavailableView("Search for Food", systemImage: "magnifyingglass")
                } else if !viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView.search(text: viewModel.searchQuery)
                }
            }
            .navigationTitle("Search Food")
            .modifier(ConditionalSearchable(searchQuery: $viewModel.searchQuery, showSearch: viewModel.favorites.isEmpty && viewModel.recentSearches.isEmpty))
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
