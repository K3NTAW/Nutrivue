import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    private let apiService = APIService()
    
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchResults: [ProductData] = []
    @Published var favorites: [ProductData] = []
    @Published var recentSearches: [ProductData] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var hasActivated = false
    
    // In-memory cache of query -> processed results
    private var resultsCache: [String: [ProductData]] = [:]
    
    // MARK: - Lifecycle
    func activate() {
        guard !hasActivated else { return }
        hasActivated = true
        loadPersistedLists()
        
        $searchQuery
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                self.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Search
    func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.searchResults = []
            return
        }
        let key = trimmed.lowercased()
        if let cached = resultsCache[key] {
            self.searchResults = cached
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let products = try await apiService.searchProducts(query: trimmed)
                let deduped = deduplicateByBarcode(products: products)
                let ranked = rank(products: deduped, for: trimmed)
                resultsCache[key] = ranked
                self.searchResults = ranked
            } catch {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.searchResults = []
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Selection
    func recordSelection(_ product: ProductData) {
        // Add to recentSearches (dedupe by code)
        var updated = recentSearches.filter { !$0.hasSameBarcode(as: product) }
        updated.insert(product, at: 0)
        if updated.count > 10 { updated = Array(updated.prefix(10)) }
        recentSearches = updated
        persistLists()
    }
    
    func toggleFavorite(_ product: ProductData) {
        if let idx = favorites.firstIndex(where: { $0.hasSameBarcode(as: product) }) {
            favorites.remove(at: idx)
        } else {
            favorites.insert(product, at: 0)
        }
        persistLists()
    }
    
    func isFavorite(_ product: ProductData) -> Bool {
        favorites.contains(where: { $0.hasSameBarcode(as: product) })
    }
    
    // MARK: - Deduplication
    func deduplicateByBarcode(products: [ProductData]) -> [ProductData] {
        var bestByCode: [String: ProductData] = [:]
        var withoutCode: [ProductData] = []
        for p in products {
            if let code = p.code, !code.isEmpty {
                if let existing = bestByCode[code] {
                    let winner = moreCompleteProduct(lhs: existing, rhs: p)
                    bestByCode[code] = winner
                } else {
                    bestByCode[code] = p
                }
            } else {
                withoutCode.append(p)
            }
        }
        return Array(bestByCode.values) + deduplicateWithoutBarcode(products: withoutCode)
    }
    
    private func deduplicateWithoutBarcode(products: [ProductData]) -> [ProductData] {
        // Fallback: group by name+image
        var seen: [String: ProductData] = [:]
        for p in products {
            let key = (p.productName ?? "").lowercased() + "|" + (p.imageUrl ?? "")
            if let existing = seen[key] {
                seen[key] = moreCompleteProduct(lhs: existing, rhs: p)
            } else {
                seen[key] = p
            }
        }
        return Array(seen.values)
    }
    
    private func moreCompleteProduct(lhs: ProductData, rhs: ProductData) -> ProductData {
        let lhsScore = nutritionCompleteness(of: lhs)
        let rhsScore = nutritionCompleteness(of: rhs)
        if lhsScore != rhsScore { return lhsScore > rhsScore ? lhs : rhs }
        // Tie-breaker: prefer one with image
        let lhsHasImage = !(lhs.imageUrl ?? "").isEmpty
        let rhsHasImage = !(rhs.imageUrl ?? "").isEmpty
        if lhsHasImage != rhsHasImage { return lhsHasImage ? lhs : rhs }
        return lhs
    }
    
    private func nutritionCompleteness(of product: ProductData) -> Int {
        let n = product.nutriments
        let fields = [n?.energyKcal100g, n?.proteins100g, n?.carbohydrates100g, n?.fat100g]
        return fields.reduce(0) { $0 + ($1 == nil ? 0 : 1) }
    }
    
    // MARK: - Ranking
    func rank(products: [ProductData], for query: String) -> [ProductData] {
        let q = query.lowercased()
        return products
            .map { product in
                let name = (product.productName ?? "").lowercased()
                let exact = name == q
                let contains = name.contains(q)
                let distance = editDistance(between: name, and: q)
                let hasImage = !(product.imageUrl ?? "").isEmpty
                let completeness = nutritionCompleteness(of: product)
                var score = 0
                if exact { score += 1000 }
                else if contains { score += 500 }
                // Smaller distance is better
                score += max(0, 300 - min(distance, 300))
                if hasImage { score += 50 }
                score += completeness * 10
                return (product, score)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    // Simple Levenshtein distance (iterative, memory-optimized)
    private func editDistance(between a: String, and b: String) -> Int {
        if a == b { return 0 }
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        let aChars = Array(a)
        let bChars = Array(b)
        var prev = Array(0...bChars.count)
        var curr = Array(repeating: 0, count: bChars.count + 1)
        for i in 1...aChars.count {
            curr[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j-1] + 1,
                    prev[j-1] + cost
                )
            }
            swap(&prev, &curr)
        }
        return prev[bChars.count]
    }
    
    // MARK: - Persistence
    private let favoritesKey = "SearchVM.favorites"
    private let recentsKey = "SearchVM.recents"
    
    private func loadPersistedLists() {
        let decoder = JSONDecoder()
        if let fData = UserDefaults.standard.data(forKey: favoritesKey),
           let list = try? decoder.decode([ProductData].self, from: fData) {
            favorites = list
        }
        if let rData = UserDefaults.standard.data(forKey: recentsKey),
           let list = try? decoder.decode([ProductData].self, from: rData) {
            recentSearches = list
        }
    }
    
    private func persistLists() {
        let encoder = JSONEncoder()
        if let fData = try? encoder.encode(favorites) {
            UserDefaults.standard.set(fData, forKey: favoritesKey)
        }
        if let rData = try? encoder.encode(recentSearches) {
            UserDefaults.standard.set(rData, forKey: recentsKey)
        }
    }
}

// MARK: - Helpers
private extension ProductData {
    func hasSameBarcode(as other: ProductData) -> Bool {
        guard let a = self.code, let b = other.code else { return false }
        return a == b
    }
}


