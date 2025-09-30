import SwiftUI

struct DesignSystem {
    struct Colors {
        // Primary Colors with Rich Gradients
        static let primary = Color(red: 0.0, green: 0.0, blue: 0.0) // Pure black
        static let secondary = Color(red: 0.05, green: 0.05, blue: 0.05) // Very dark gray
        static let accent = Color(red: 0.0, green: 0.8, blue: 1.0) // Bright blue
        
        // Macro Colors with Gradients
        static let calories = Color(red: 1.0, green: 0.3, blue: 0.3) // Red
        static let protein = Color(red: 0.3, green: 0.7, blue: 1.0) // Blue
        static let carbs = Color(red: 0.2, green: 0.9, blue: 0.4) // Bright green
        static let fat = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        
        // Status Colors
        static let success = Color(red: 0.2, green: 0.9, blue: 0.4) // Bright green
        static let warning = Color(red: 1.0, green: 0.7, blue: 0.0) // Orange
        static let error = Color(red: 1.0, green: 0.2, blue: 0.2) // Red
        
        // Background Colors
        static let background = Color(red: 0.0, green: 0.0, blue: 0.0) // Pure black
        static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.08) // Very dark gray
        static let surface = Color(red: 0.12, green: 0.12, blue: 0.12) // Dark gray
        
        // Text Colors
        static let primaryText = Color.white
        static let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8) // Light gray
        static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6) // Medium gray
        
        // Border Colors
        static let border = Color(red: 0.15, green: 0.15, blue: 0.15) // Dark gray
        
        // Gradient Colors (Ultrahuman style)
        static let recoveryGradient = LinearGradient(
            colors: [Color(red: 0.0, green: 0.6, blue: 0.8), Color(red: 0.0, green: 0.8, blue: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let sleepGradient = LinearGradient(
            colors: [Color(red: 0.8, green: 0.2, blue: 0.4), Color(red: 0.6, green: 0.2, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let movementGradient = LinearGradient(
            colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.0, green: 0.9, blue: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let caffeineGradient = LinearGradient(
            colors: [Color(red: 0.8, green: 0.4, blue: 0.2), Color(red: 0.9, green: 0.6, blue: 0.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Adaptive Colors for Dark/Light Mode
        static func adaptiveBackground() -> Color {
            Color(UIColor.systemBackground)
        }
        
        static func adaptiveCardBackground() -> Color {
            Color(UIColor.secondarySystemBackground)
        }
        
        static func adaptiveSurface() -> Color {
            Color(UIColor.tertiarySystemBackground)
        }
        
        static func adaptivePrimaryText() -> Color {
            Color(UIColor.label)
        }
        
        static func adaptiveSecondaryText() -> Color {
            Color(UIColor.secondaryLabel)
        }
        
        static func adaptiveTertiaryText() -> Color {
            Color(UIColor.tertiaryLabel)
        }
        
        static func adaptiveBorder() -> Color {
            Color(UIColor.separator)
        }
    }
    
    struct Typography {
        // Large Display
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        // Body Text
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Metric Display (Ultrahuman style)
        static let metricLarge = Font.system(size: 48, weight: .bold, design: .default)
        static let metricMedium = Font.system(size: 32, weight: .bold, design: .default)
        static let metricSmall = Font.system(size: 24, weight: .semibold, design: .default)
    }
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
    }
    
    struct Shadows {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let large = Color.black.opacity(0.2)
    }
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Card Style Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.adaptiveCardBackground())
                    .shadow(color: DesignSystem.Shadows.small, radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.adaptiveBorder(), lineWidth: 0.5)
            )
    }
}

struct DataCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.adaptiveCardBackground())
                    .shadow(color: DesignSystem.Shadows.medium, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(DesignSystem.Colors.adaptiveBorder(), lineWidth: 0.5)
            )
    }
}

struct MetricCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.adaptiveSurface())
                    .shadow(color: DesignSystem.Shadows.small, radius: 1, x: 0, y: 1)
            )
    }
}

struct SubtleCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.5))
            )
    }
}

// MARK: - Gradient Card Styles (Ultrahuman inspired)
struct GradientCardStyle: ViewModifier {
    let gradient: LinearGradient
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(gradient)
                    .shadow(color: DesignSystem.Shadows.medium, radius: 6, x: 0, y: 3)
            )
    }
}

struct RecoveryCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(GradientCardStyle(gradient: DesignSystem.Colors.recoveryGradient))
    }
}

struct SleepCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(GradientCardStyle(gradient: DesignSystem.Colors.sleepGradient))
    }
}

struct MovementCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(GradientCardStyle(gradient: DesignSystem.Colors.movementGradient))
    }
}

struct CaffeineCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(GradientCardStyle(gradient: DesignSystem.Colors.caffeineGradient))
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func dataCardStyle() -> some View {
        modifier(DataCardStyle())
    }
    
    func metricCardStyle() -> some View {
        modifier(MetricCardStyle())
    }
    
    func subtleCardStyle() -> some View {
        modifier(SubtleCardStyle())
    }
    
    func recoveryCardStyle() -> some View {
        modifier(RecoveryCardStyle())
    }
    
    func sleepCardStyle() -> some View {
        modifier(SleepCardStyle())
    }
    
    func movementCardStyle() -> some View {
        modifier(MovementCardStyle())
    }
    
    func caffeineCardStyle() -> some View {
        modifier(CaffeineCardStyle())
    }
}
