import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.date) private var meals: [Meal]
    
    @State private var showingAddFoodSheet = false
    @State private var showingScannerSheet = false
    @State private var showingFoodSearchSheet = false
    @State private var selectedMeal: Meal?
    @State private var scannedBarcode: String?
    
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
            .sheet(isPresented: $showingAddFoodSheet) {
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
                BarcodeScannerView(scannedCode: $scannedBarcode)
            }
            .onAppear(perform: createTodaysMealsIfNeeded)
            .onChange(of: scannedBarcode) {
                if let barcode = scannedBarcode {
                    foodLookupViewModel.fetchProduct(barcode: barcode)
                }
            }
            .onChange(of: foodLookupViewModel.product) {
                if foodLookupViewModel.product != nil {
                    // This logic now correctly triggers only for barcode scans.
                    // We need a selected meal to add to. Defaulting to the first meal of the day.
                    selectedMeal = todaysMeals.first
                    showingAddFoodSheet = true
                }
            }
        }
    }
    
    private func createTodaysMealsIfNeeded() {
        if todaysMeals.isEmpty {
            let mealNames = ["Breakfast", "Lunch", "Dinner", "Snacks"]
            for name in mealNames {
                let newMeal = Meal(name: name, items: [], date: Date())
                modelContext.insert(newMeal)
            }
        }
    }
}


#Preview {
    LogView()
        .modelContainer(for: [Meal.self, FoodItem.self], inMemory: true)
}
