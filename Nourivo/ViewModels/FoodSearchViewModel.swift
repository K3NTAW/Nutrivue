import Foundation
import Combine

@MainActor
class FoodSearchViewModel: ObservableObject {
    private let apiService = APIService()
    
    @Published var searchQuery = ""
    @Published var searchResults: [ProductData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var hasActivated = false

    func activate() {
        guard !hasActivated else { return }
        hasActivated = true
        
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    func performSearch(query: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let products = try await apiService.searchProducts(query: query)
                self.searchResults = products
            } catch {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
