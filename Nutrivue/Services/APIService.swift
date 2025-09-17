import Foundation

class APIService {
    func fetchProduct(barcode: String) async throws -> ProductData? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ProductResponse.self, from: data)
        
        return response.product
    }
    
    func searchProducts(query: String) async throws -> [ProductData] {
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(query)&search_simple=1&action=process&json=1"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ProductSearchResponse.self, from: data)
        
        return response.products
    }
}
