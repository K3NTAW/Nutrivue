import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: SearchViewModel
    @State private var showingAddFoodManually = false
    @State private var selectedProduct: ProductData?
    
    let meal: Meal
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ProgressView()
                                .tint(DesignSystem.Colors.accent)
                            Text("Searching...")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.sm) {
                            // Favorites Section
                            if !viewModel.favorites.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(DesignSystem.Colors.accent)
                                            .font(.title3)
                                        
                                        Text("Favorites")
                                            .font(DesignSystem.Typography.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    
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
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                    }
                                }
                            }
                            
                            // Recent Searches Section
                            if !viewModel.recentSearches.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(DesignSystem.Colors.accent)
                                            .font(.title3)
                                        
                                        Text("Recent Searches")
                                            .font(DesignSystem.Typography.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        
                                        Spacer()
                                        
                                        Button("Clear") {
                                            viewModel.clearRecents()
                                        }
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    
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
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                    }
                                }
                            }
                            
                            // Search Results
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
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.sm)
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
            .sheet(item: $selectedProduct) { product in
                AddFoodView(meal: meal, product: product)
            }
            .onAppear {
                viewModel.activate()
            }
        }
    }
}
