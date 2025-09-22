import Foundation

struct ParsedIngredientLine {
    let name: String
    let quantity: Double? // in original units
    let unit: String?
}

class RecipeImportService {
    private let api = APIService()
    
    func importFromOCR(text: String) async -> ([RecipeIngredient], Double) {
        let servings = detectServings(in: text) ?? 1
        let lines = extractIngredientLines(from: text)
        var ingredients: [RecipeIngredient] = []
        for line in lines {
            let grams = convertToGrams(quantity: line.quantity, unit: line.unit)
            guard let product = try? await pickBestProduct(for: line.name) else {
                // If no product found, create placeholder with zeros
                let ing = RecipeIngredient(
                    name: line.name.capitalized,
                    amountGrams: grams ?? 0,
                    caloriesPer100g: 0,
                    proteinPer100g: 0,
                    carbsPer100g: 0,
                    fatPer100g: 0
                )
                ingredients.append(ing)
                continue
            }
            let nutr = product.nutriments
            let ing = RecipeIngredient(
                name: product.productName ?? line.name.capitalized,
                amountGrams: grams ?? 0,
                caloriesPer100g: nutr?.energyKcal100g ?? 0,
                proteinPer100g: nutr?.proteins100g ?? 0,
                carbsPer100g: nutr?.carbohydrates100g ?? 0,
                fatPer100g: nutr?.fat100g ?? 0,
                sourceBarcode: product.code,
                sourceImageUrl: product.imageUrl
            )
            ingredients.append(ing)
        }
        return (ingredients, Double(servings))
    }
    
    private func detectServings(in text: String) -> Int? {
        let patterns = [
            "servings?\\s*[:=]\\s*(\\d+)",
            "makes\\s*(\\d+)"
        ]
        for pat in patterns {
            if let m = text.range(of: pat, options: [.regularExpression, .caseInsensitive]) {
                let sub = String(text[m])
                if let num = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).joined().toInt() { return num }
            }
        }
        return nil
    }
    
    private func extractIngredientLines(from text: String) -> [ParsedIngredientLine] {
        // 1) Try to isolate an Ingredients section
        let allLines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let lower = allLines.map { $0.lowercased() }
        let startIdx = lower.firstIndex { $0.contains("ingredient") }
        let stopHeaders = ["instruction", "method", "direction", "step", "preparation", "prep", "notes", "nutrition", "serving", "yield"]
        var endIdx: Int? = nil
        if let si = startIdx {
            for i in (si+1)..<lower.count {
                if stopHeaders.contains(where: { lower[i].hasPrefix($0) }) {
                    endIdx = i
                    break
                }
            }
        }
        let candidateLines: [String]
        if let si = startIdx {
            let end = endIdx ?? allLines.count
            candidateLines = Array(allLines[(si+1)..<end])
        } else {
            candidateLines = allLines
        }

        // 2) Keep only lines that look like ingredients
        let unitPattern = "(cups?|tbsp|tablespoons?|tsp|teaspoons?|g|gram|grams|kg|ml|l|oz|ounce|ounces|lb|lbs)"
        let qtyUnitRegex = try? NSRegularExpression(
            pattern: "^([0-9\\/\\.\\-\\s]+)\\s+" + unitPattern + "\\b[\\s,]*(.*)$",
            options: [.caseInsensitive]
        )
        let bulletRegex = try? NSRegularExpression(
            pattern: "^([\\-\\*•]\\s+)(.+)$",
            options: []
        )
        let ignoreWords = ["preheat", "oven", "minute", "hour", "cook", "bake", "heat", "mix", "stir", "blend", "serve", "title", "recipe", "ingredients", "instructions", "method", "direction", "step", "preparation", "prep", "note", "nutrition", "serving", "yield", "makes", "calories"]

        func isLikelyIngredient(_ line: String) -> Bool {
            let lower = line.lowercased()
            if ignoreWords.contains(where: { lower.contains($0) }) { return false }
            if let m = qtyUnitRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)), m.numberOfRanges >= 4 {
                return true
            }
            if let bm = bulletRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)), bm.numberOfRanges >= 3 {
                // bullet with at least one digit or common unit word
                let content = (line as NSString).substring(from: bm.range(at: 2).location)
                let hasAlpha = content.rangeOfCharacter(from: .letters) != nil
                let hasQtyOrUnit = content.range(of: unitPattern, options: [.regularExpression, .caseInsensitive]) != nil
                    || content.range(of: "[0-9]", options: [.regularExpression]) != nil
                return hasAlpha && hasQtyOrUnit
            }
            // Standalone quantity without explicit unit (e.g., "2 eggs")
            if let re = try? NSRegularExpression(pattern: "^[0-9\\/\\.]+\\s+([a-zA-Z].*)$", options: []) {
                if re.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)) != nil {
                    return true
                }
            }
            return false
        }

        var result: [ParsedIngredientLine] = []
        for raw in candidateLines where isLikelyIngredient(raw) {
            // Parse quantity+unit if present
            if let regex = qtyUnitRegex {
                let range = NSRange(location: 0, length: (raw as NSString).length)
                if let match = regex.firstMatch(in: raw, options: [], range: range) {
                    let qtyStr = match.group(1, in: raw)
                    let unit = match.group(2, in: raw)
                    var name = match.group(3, in: raw)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? raw
                    name = name.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "-", with: " ")
                    let qty = parseQuantity(qtyStr)
                    result.append(ParsedIngredientLine(name: name, quantity: qty, unit: unit))
                    continue
                }
            }
            // Bullet or quantity without unit
            var cleaned = raw
            if let m = bulletRegex?.firstMatch(in: raw, options: [], range: NSRange(location: 0, length: (raw as NSString).length)) {
                cleaned = (raw as NSString).substring(from: m.range(at: 2).location)
            }
            cleaned = cleaned.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "-", with: " ")
            // Try to split first token as quantity
            let tokens = cleaned.split(separator: " ")
            if let first = tokens.first, parseQuantity(String(first)) != nil {
                let qty = parseQuantity(String(first))
                let name = tokens.dropFirst().joined(separator: " ")
                result.append(ParsedIngredientLine(name: name, quantity: qty, unit: nil))
            } else {
                result.append(ParsedIngredientLine(name: cleaned, quantity: nil, unit: nil))
            }
        }
        return result
    }
    
    private func parseQuantity(_ s: String?) -> Double? {
        guard var s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        s = s.replacingOccurrences(of: "-", with: " ")
        // Handle ranges like "1-2" => midpoint
        if s.contains(" ") || s.contains("-") {
            let parts = s.split{ $0 == " " || $0 == "-" }
            let vals = parts.compactMap { parseSingleQuantity(String($0)) }
            if vals.count == 2 { return (vals[0] + vals[1]) / 2 }
            if let v = vals.first { return v }
            return nil
        }
        return parseSingleQuantity(s)
    }
    
    private func parseSingleQuantity(_ s: String) -> Double? {
        // Fraction like 1/2 or mixed 1 1/2 already split earlier
        if s.contains("/") {
            let parts = s.split(separator: "/")
            if parts.count == 2, let n = Double(parts[0]), let d = Double(parts[1]), d != 0 { return n/d }
        }
        return Double(s)
    }
    
    private func convertToGrams(quantity: Double?, unit: String?) -> Double? {
        guard let q = quantity else { return nil }
        guard let u = unit?.lowercased() else { return q } // assume grams
        switch u {
        case "g", "gram", "grams": return q
        case "kg": return q * 1000
        case "oz", "ounce", "ounces": return q * 28.349523125
        case "lb", "lbs": return q * 453.59237
        case "ml": return q // assume water density
        case "l": return q * 1000
        case "cup", "cups": return q * 240 // generic
        case "tbsp", "tablespoon", "tablespoons": return q * 15
        case "tsp", "teaspoon", "teaspoons": return q * 5
        default: return q
        }
    }
    
    private func pickBestProduct(for name: String) async throws -> ProductData? {
        let products = try await api.searchProducts(query: name)
        guard !products.isEmpty else { return nil }
        // Simple ranking: exact > contains > image > completeness
        let q = name.lowercased()
        func completeness(_ p: ProductData) -> Int {
            let n = p.nutriments
            return [n?.energyKcal100g, n?.proteins100g, n?.carbohydrates100g, n?.fat100g].reduce(0){ $0 + ($1 == nil ? 0 : 1) }
        }
        let ranked = products.map { p -> (ProductData, Int) in
            let n = (p.productName ?? "").lowercased()
            var score = 0
            if n == q { score += 1000 } else if n.contains(q) { score += 500 }
            if let img = p.imageUrl, !img.isEmpty { score += 50 }
            score += completeness(p) * 10
            return (p, score)
        }.sorted { $0.1 > $1.1 }.map { $0.0 }
        return ranked.first
    }
}

private extension NSTextCheckingResult {
    func group(_ idx: Int, in s: String) -> String? {
        let r = range(at: idx)
        guard r.location != NSNotFound, let sr = Range(r, in: s) else { return nil }
        let sub = String(s[sr])
        return sub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sub
    }
}

private extension String {
    func toInt() -> Int? { Int(self) }
}


