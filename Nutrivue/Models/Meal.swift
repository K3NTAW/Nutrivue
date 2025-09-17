import Foundation
import SwiftData

@Model
class Meal {
    let id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var items: [FoodItem]
    var date: Date
    
    init(name: String, items: [FoodItem], date: Date) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.date = date
    }
}
