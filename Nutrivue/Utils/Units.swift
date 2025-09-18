import Foundation

enum MassUnitFormatter {
    static func formatMacro(grams: Double, unitSystem: UnitSystem) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f g", grams)
        case .imperial:
            let ounces = grams / 28.349523125
            return String(format: "%.1f oz", ounces)
        }
    }
}


