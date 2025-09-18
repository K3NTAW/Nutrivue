import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var servings: Double = 1
    @State private var ingredients: [RecipeIngredient] = []
    @State private var showingSearch = false
    @State private var selectedProduct: ProductData?
    @State private var showingScanner = false
    @State private var scannedProduct: ProductData?
    @State private var scanGramsText: String = "100"
    @StateObject private var foodLookupVM = FoodLookupViewModel()
    @StateObject private var searchVM = SearchViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Recipe name", text: $name)
                    TextField("Notes (optional)", text: $notes)
                    Stepper(value: $servings, in: 0.1...50, step: 0.5) {
                        Text("Servings: \(servings, specifier: "%.1f")")
                    }
                }
                Section(header: Text("Ingredients")) {
                    if ingredients.isEmpty {
                        Text("No ingredients yet").foregroundColor(.secondary)
                    } else {
                        ForEach(ingredients, id: \.id) { ing in
                            IngredientRow(ingredient: ing)
                        }
                        .onDelete { idx in
                            ingredients.remove(atOffsets: idx)
                        }
                    }
                    Button {
                        showingSearch = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus")
                    }
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                }
                Section(header: Text("Totals")) {
                    let totals = totalsText()
                    Text(totals)
                }
                Section(header: Text("Per Serving")) {
                    let per = perServingText()
                    Text(per)
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || ingredients.isEmpty || servings <= 0)
                }
            }
            .sheet(isPresented: $showingSearch) {
                IngredientSearchView(searchVM: searchVM) { product, grams in
                    if let nutr = product.nutriments {
                        let ing = RecipeIngredient(
                            name: product.productName ?? "Ingredient",
                            amountGrams: grams,
                            caloriesPer100g: nutr.energyKcal100g ?? 0,
                            proteinPer100g: nutr.proteins100g ?? 0,
                            carbsPer100g: nutr.carbohydrates100g ?? 0,
                            fatPer100g: nutr.fat100g ?? 0,
                            sourceBarcode: product.code,
                            sourceImageUrl: product.imageUrl
                        )
                        ingredients.append(ing)
                    }
                    showingSearch = false
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { barcode in
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showingScanner = false
                    foodLookupVM.fetchProduct(barcode: barcode)
                }
            }
            .sheet(item: $scannedProduct) { product in
                NavigationView {
                    Form {
                        Section(header: Text(product.productName ?? "Ingredient")) {
                            TextField("Amount (g)", text: $scanGramsText).keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Amount")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Back") { scannedProduct = nil } }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Add") {
                                if let nutr = product.nutriments {
                                    let grams = Double(scanGramsText) ?? 100
                                    let ing = RecipeIngredient(
                                        name: product.productName ?? "Ingredient",
                                        amountGrams: grams,
                                        caloriesPer100g: nutr.energyKcal100g ?? 0,
                                        proteinPer100g: nutr.proteins100g ?? 0,
                                        carbsPer100g: nutr.carbohydrates100g ?? 0,
                                        fatPer100g: nutr.fat100g ?? 0,
                                        sourceBarcode: product.code,
                                        sourceImageUrl: product.imageUrl
                                    )
                                    ingredients.append(ing)
                                }
                                foodLookupVM.product = nil
                                scannedProduct = nil
                            }
                        }
                    }
                }
            }
            .onChange(of: foodLookupVM.product) {
                if let p = foodLookupVM.product { scannedProduct = p }
            }
            .alert("Product Not Found", isPresented: $foodLookupVM.productNotFound) {
                Button("OK", role: .cancel) { resetScanState() }
            }
            .alert("Error", isPresented: .constant(foodLookupVM.errorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    resetScanState()
                    foodLookupVM.errorMessage = nil
                }
            }, message: {
                Text(foodLookupVM.errorMessage ?? "An unknown error occurred.")
            })
            .overlay {
                if foodLookupVM.isLoading {
                    ZStack {
                        Color(white: 0, opacity: 0.75).ignoresSafeArea()
                        VStack {
                            ProgressView().tint(.white)
                            Text("Searching...").foregroundColor(.white).padding(.top)
                        }
                    }
                }
            }
        }
    }
    
    private func totalsText() -> String {
        let cal = ingredients.reduce(0) { $0 + $1.totals().cal }
        let p = ingredients.reduce(0) { $0 + $1.totals().p }
        let c = ingredients.reduce(0) { $0 + $1.totals().c }
        let f = ingredients.reduce(0) { $0 + $1.totals().f }
        return String(format: "%.0f kcal, P %.1f g, C %.1f g, F %.1f g", cal, p, c, f)
    }
    
    private func perServingText() -> String {
        let cal = ingredients.reduce(0) { $0 + $1.totals().cal } / max(servings, 1)
        let p = ingredients.reduce(0) { $0 + $1.totals().p } / max(servings, 1)
        let c = ingredients.reduce(0) { $0 + $1.totals().c } / max(servings, 1)
        let f = ingredients.reduce(0) { $0 + $1.totals().f } / max(servings, 1)
        return String(format: "%.0f kcal, P %.1f g, C %.1f g, F %.1f g", cal, p, c, f)
    }
    
    private func save() {
        let recipe = Recipe(name: name.trimmingCharacters(in: .whitespacesAndNewlines), notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes, servings: servings, ingredients: ingredients)
        modelContext.insert(recipe)
        dismiss()
    }
    
    private func resetScanState() {
        foodLookupVM.product = nil
        foodLookupVM.productNotFound = false
    }
}

private struct IngredientRow: View {
    let ingredient: RecipeIngredient
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let url = URL(string: ingredient.sourceImageUrl ?? "") {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                    .frame(width: 44, height: 44).clipped().cornerRadius(6)
            } else {
                ZStack { Color.gray.opacity(0.15); Image(systemName: "photo").foregroundColor(.gray) }
                    .frame(width: 44, height: 44).cornerRadius(6)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                Text(String(format: "%.0f g", ingredient.amountGrams)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            let t = ingredient.totals()
            Text(String(format: "%.0f kcal", t.cal)).foregroundColor(.secondary)
        }
    }
}

private struct IngredientSearchView: View {
    @ObservedObject var searchVM: SearchViewModel
    var onPick: (ProductData, Double) -> Void
    @State private var gramsText: String = "100"
    @State private var pickedProduct: ProductData?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                List(searchVM.searchResults) { product in
                    Button {
                        pickedProduct = product
                    } label: {
                        HStack {
                            if let u = URL(string: product.imageUrl ?? "") {
                                AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                                    .frame(width: 44, height: 44).clipped().cornerRadius(6)
                            }
                            Text(product.productName ?? "Item")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .searchable(text: $searchVM.searchQuery)
                .onAppear { searchVM.activate() }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(item: $pickedProduct) { p in
                NavigationView {
                    Form {
                        Section(header: Text(p.productName ?? "Ingredient")) {
                            TextField("Amount (g)", text: $gramsText).keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Amount")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Back") { pickedProduct = nil } }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Add") {
                                let grams = Double(gramsText) ?? 100
                                onPick(p, grams)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}


