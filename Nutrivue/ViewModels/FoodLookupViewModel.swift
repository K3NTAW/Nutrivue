import Foundation

@MainActor
class FoodLookupViewModel: ObservableObject {
    private let apiService = APIService()
    
    @Published var product: ProductData?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func fetchProduct(barcode: String) {
        isLoading = true
        errorMessage = nil
        product = nil
        
        Task {
            do {
                let product = try await apiService.fetchProduct(barcode: barcode)
                self.product = product
            } catch {
                self.errorMessage = "Failed to fetch product: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
