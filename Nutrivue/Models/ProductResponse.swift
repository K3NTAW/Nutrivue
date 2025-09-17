import Foundation

// This file defines the structure for decoding the JSON response from the Open Food Facts API.

struct ProductResponse: Codable {
    let product: ProductData?
}

struct ProductSearchResponse: Codable {
    let products: [ProductData]
}

struct ProductData: Codable, Equatable, Identifiable {
    var id: String { productName ?? UUID().uuidString }
    let productName: String?
    let nutriments: Nutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
    }
}

struct Nutriments: Codable, Equatable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
