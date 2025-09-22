import SwiftUI
import SwiftData
import WidgetKit
import UIKit

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
    @State private var showingOCRSheet = false
    @State private var ocrProcessing = false
    @State private var ocrAlertMessage: String?
    
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
                    Button {
                        showingOCRSheet = true
                    } label: {
                        Label("Scan Recipe (OCR)", systemImage: "doc.text.viewfinder")
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
            .sheet(isPresented: $showingOCRSheet) {
                RecipeOCRSheet { text in
                    ocrProcessing = true
                    Task {
                        if let apiKey = UserDefaults.standard.string(forKey: "OpenRouterAPIKey"), !apiKey.isEmpty {
                            do {
                                let model = UserDefaults.standard.string(forKey: "OpenRouterModel") ?? "openrouter/anthropic/claude-3.5-sonnet"
                                let service = OpenRouterRecipeService()
                                let ai = try await service.parseRecipe(ocrText: text, options: .init(apiKey: apiKey, model: model, referer: "https://nutrivue.app", title: "Nutrivue"))
                                await MainActor.run {
                                    if let n = ai.name, self.name.trimmingCharacters(in: .whitespaces).isEmpty { self.name = String(n.prefix(40)) }
                                    if let s = ai.servings, s > 0 { self.servings = s }
                                    var created: [RecipeIngredient] = []
                                    for ing in ai.ingredients {
                                        let grams = ing.grams ?? OpenRouterRecipeService.convertToGrams(quantity: ing.quantity, unit: ing.unit) ?? 0
                                        let ri = RecipeIngredient(name: ing.name, amountGrams: grams, caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0)
                                        created.append(ri)
                                    }
                                    self.ingredients.append(contentsOf: created)
                                    ocrProcessing = false
                                }
                            } catch {
                                await MainActor.run { ocrAlertMessage = "AI parsing failed. Falling back to local parser." }
                                let importer = RecipeImportService()
                                let (autoIngredients, autoServings) = await importer.importFromOCR(text: text)
                                await MainActor.run {
                                    self.ingredients.append(contentsOf: autoIngredients)
                                    if autoServings > 0 { self.servings = autoServings }
                                    ocrProcessing = false
                                }
                            }
                        } else {
                            let importer = RecipeImportService()
                            let (autoIngredients, autoServings) = await importer.importFromOCR(text: text)
                            await MainActor.run {
                                if autoIngredients.isEmpty {
                                    ocrAlertMessage = "No ingredients detected. Try a clearer photo focused on the Ingredients list."
                                } else {
                                    self.ingredients.append(contentsOf: autoIngredients)
                                    if autoServings > 0 { self.servings = autoServings }
                                    if self.name.trimmingCharacters(in: .whitespaces).isEmpty {
                                        if let first = text.split(separator: "\n").first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                                            self.name = String(first.prefix(40))
                                        } else {
                                            self.name = "Imported Recipe"
                                        }
                                    }
                                }
                                ocrProcessing = false
                            }
                        }
                    }
                }
            }
            .sheet(item: $scannedProduct) { product in
                AdjustServingSheet(productName: product.productName ?? "Ingredient",
                                    caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
                                    proteinPer100g: product.nutriments?.proteins100g ?? 0,
                                    carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
                                    fatPer100g: product.nutriments?.fat100g ?? 0,
                                    onConfirm: { grams in
                    let ing = RecipeIngredient(
                        name: product.productName ?? "Ingredient",
                        amountGrams: grams,
                        caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
                        proteinPer100g: product.nutriments?.proteins100g ?? 0,
                        carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
                        fatPer100g: product.nutriments?.fat100g ?? 0,
                        sourceBarcode: product.code,
                        sourceImageUrl: product.imageUrl
                    )
                    ingredients.append(ing)
                    foodLookupVM.product = nil
                    scannedProduct = nil
                }, onCancel: {
                    scannedProduct = nil
                })
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
                if ocrProcessing {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Importing recipe...").foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    }
                }
            }
            .alert("Import Failed", isPresented: Binding(get: { ocrAlertMessage != nil }, set: { if !$0 { ocrAlertMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(ocrAlertMessage ?? "")
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
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
        dismiss()
    }
    
    private func resetScanState() {
        foodLookupVM.product = nil
        foodLookupVM.productNotFound = false
    }
}

// Minimal OCR picker to choose Camera or Photo Library, then run OCR
private struct RecipeOCRSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onTextExtracted: (String) -> Void
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pickedImages: [UIImage] = []

    var body: some View {
        NavigationView {
            List {
                Button { showCamera = true } label: { Label("Scan with Camera", systemImage: "camera.viewfinder") }
                Button { showLibrary = true } label: { Label("Import Photo", systemImage: "photo.on.rectangle") }
            }
            .navigationTitle("Import Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(images: $pickedImages)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(onCapture: { image in
                    if let image = image {
                        TextRecognitionService().recognizeText(from: [image]) { text in
                            onTextExtracted(text)
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
                }, onCancel: { dismiss() })
            }
            .onChange(of: pickedImages) {
                guard !pickedImages.isEmpty else { return }
                let imgs = pickedImages
                pickedImages = []
                TextRecognitionService().recognizeText(from: imgs) { text in
                    onTextExtracted(text)
                    dismiss()
                }
            }
        }
    }
}

// Simple UIKit-backed picker for one or more photos
private struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(parent: self) }
    class Coord: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage { parent.images = [img] }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
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
                List {
                    if !searchVM.favorites.isEmpty {
                        Section("Favorites") {
                            ForEach(searchVM.favorites) { product in
                                Button(action: {
                                    pickedProduct = product
                                    searchVM.recordSelection(product)
                                }) {
                                    SearchRow(product: product, query: searchVM.searchQuery, isFavorite: true) {
                                        searchVM.toggleFavorite(product)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if !searchVM.recentSearches.isEmpty {
                        Section(header: HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear") {
                                searchVM.clearRecents()
                            }
                        }) {
                            ForEach(searchVM.recentSearches) { product in
                                Button(action: {
                                    pickedProduct = product
                                    searchVM.recordSelection(product)
                                }) {
                                    SearchRow(product: product, query: searchVM.searchQuery, isFavorite: searchVM.isFavorite(product)) {
                                        searchVM.toggleFavorite(product)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    ForEach(searchVM.searchResults) { product in
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
                }
                .searchable(text: $searchVM.searchQuery)
                .onAppear { searchVM.activate() }
                .overlay {
                    if searchVM.searchQuery.isEmpty && searchVM.searchResults.isEmpty {
                        ContentUnavailableView("Search for Ingredients", systemImage: "magnifyingglass")
                    } else if !searchVM.searchQuery.isEmpty && searchVM.searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchVM.searchQuery)
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(item: $pickedProduct) { p in
                AdjustServingSheet(productName: p.productName ?? "Ingredient",
                                   caloriesPer100g: p.nutriments?.energyKcal100g ?? 0,
                                   proteinPer100g: p.nutriments?.proteins100g ?? 0,
                                   carbsPer100g: p.nutriments?.carbohydrates100g ?? 0,
                                   fatPer100g: p.nutriments?.fat100g ?? 0,
                                   onConfirm: { grams in
                    onPick(p, grams)
                    dismiss()
                }, onCancel: {
                    pickedProduct = nil
                })
            }
        }
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (UIImage?) -> Void
    var onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coord { Coord(parent: self) }
    
    class Coord: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(parent: CameraCaptureView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = info[.originalImage] as? UIImage
            parent.onCapture(img)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
}


