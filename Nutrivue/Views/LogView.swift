import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \Meal.date) private var meals: [Meal]
    
    @State private var showingAddFoodSheet = false
    @State private var showingScannerSheet = false
    @State private var showingFoodSearchSheet = false
    @State private var selectedMeal: Meal?
    
    @StateObject private var foodLookupViewModel = FoodLookupViewModel()
    
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
                            selectedMeal = meal
                            showingFoodSearchSheet.toggle()
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
            .sheet(isPresented: $showingAddFoodSheet, onDismiss: resetScanState) {
                if let selectedMeal {
                    AddFoodView(meal: selectedMeal, product: foodLookupViewModel.product)
                }
            }
            .sheet(isPresented: $showingFoodSearchSheet) {
                if let selectedMeal {
                    FoodSearchView(meal: selectedMeal)
                }
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
                    // This logic now correctly triggers only for barcode scans.
                    selectedMeal = todaysMeals.first
                    showingAddFoodSheet = true
                }
            }
            .alert("Product Not Found", isPresented: $foodLookupViewModel.productNotFound) {
                Button("Add Manually") {
                    selectedMeal = todaysMeals.first
                    foodLookupViewModel.product = nil // Ensure we are in manual mode
                    showingAddFoodSheet = true
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


