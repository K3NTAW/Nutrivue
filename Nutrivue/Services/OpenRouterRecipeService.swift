import Foundation

struct AIRecipe: Decodable {
    struct Ingredient: Decodable {
        let name: String
        let quantity: Double?
        let unit: String?
        let grams: Double?
        let notes: String?
    }
    let name: String?
    let servings: Double?
    let ingredients: [Ingredient]
}

class OpenRouterRecipeService {
    struct Options {
        let apiKey: String
        let model: String
        let referer: String
        let title: String
    }
    
    func parseRecipe(ocrText: String, options: Options) async throws -> AIRecipe {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(options.apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue(options.referer, forHTTPHeaderField: "HTTP-Referer")
        req.addValue(options.title, forHTTPHeaderField: "X-Title")
        
        let system = """
        You extract recipes from noisy OCR text. Output STRICT JSON only (no prose):
        {
          "name": string|null,
          "servings": number|null,
          "ingredients": [
            { "name": string, "quantity": number|null, "unit": string|null, "grams": number|null, "notes": string|null }
          ]
        }
        Rules:
        - Only include true ingredients (skip instructions/titles/notes).
        - Convert common units to grams when feasible; otherwise leave grams null but keep quantity/unit.
        - If servings mentioned, set it; else null.
        - No extra fields, no trailing commas, no markdown, no code fences.
        """
        
        let user = """
        OCR_TEXT:
        \(ocrText)
        """
        
        let body: [String: Any] = [
            "model": options.model,
            "temperature": 0,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: req)
        
        struct ORMessage: Decodable { let content: String }
        struct ORChoice: Decodable { let message: ORMessage }
        struct ORResp: Decodable { let choices: [ORChoice] }
        let resp = try JSONDecoder().decode(ORResp.self, from: data)
        guard let content = resp.choices.first?.message.content else {
            throw NSError(domain: "OpenRouter", code: 1, userInfo: [NSLocalizedDescriptionKey: "No content from model"])
        }
        let jsonString = Self.stripCodeFences(content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenRouter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 JSON"])
        }
        return try JSONDecoder().decode(AIRecipe.self, from: jsonData)
    }
    
    private static func stripCodeFences(_ s: String) -> String {
        var out = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.hasPrefix("```") {
            out = out.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return out
    }
    
    // Generic unit conversion fallback when grams not provided by AI
    static func convertToGrams(quantity: Double?, unit: String?) -> Double? {
        guard let q = quantity else { return nil }
        guard let u = unit?.lowercased() else { return q }
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
}


