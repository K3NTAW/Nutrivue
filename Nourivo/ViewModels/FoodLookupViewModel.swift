import Foundation

@MainActor
class FoodLookupViewModel: ObservableObject {
    private let apiService = APIService()
    
    @Published var product: ProductData?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var productNotFound = false
    
    func fetchProduct(barcode: String) {
        isLoading = true
        errorMessage = nil
        product = nil
        productNotFound = false
        
        Task {
            do {
                if let product = try await apiService.fetchProduct(barcode: barcode) {
                    self.product = product
                } else {
                    self.productNotFound = true
                }
            } catch {
                self.errorMessage = "Failed to fetch product: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
