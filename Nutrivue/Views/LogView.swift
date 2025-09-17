import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \Meal.date) private var meals: [Meal]
    
    @State private var showingScannerSheet = false
    // Use item-bound sheets to avoid race where content evaluates with nil meal on first presentation
    @State private var mealForSearch: Meal?
    @State private var mealForAdd: Meal?
    @State private var showingMealPicker = false
    
    @StateObject private var foodLookupViewModel = FoodLookupViewModel()
    @StateObject private var foodSearchViewModel = SearchViewModel()
    
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(todaysMeals) { meal in
                    Section(header: Text(meal.name)) {
                        ForEach(meal.items) { item in
                            Text(item.name)
                        }
                        .onDelete { indexSet in
                            deleteFoodItem(from: meal, at: indexSet)
                        }
                        
                        Button(action: {
                            mealForSearch = meal
                        }) {
                            Label("Add Food", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Log Food")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingScannerSheet = true
                    }) {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
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
    }
    
    private func deleteFoodItem(from meal: Meal, at offsets: IndexSet) {
        meal.items.remove(atOffsets: offsets)
    }
    
    private func resetScanState() {
        foodLookupViewModel.product = nil
        foodLookupViewModel.productNotFound = false
    }
    
}


#Preview {
    LogView()
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}


