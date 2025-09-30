import SwiftUI
import SwiftData

struct AdjustServingSheet: View {
    let productName: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    var initialGrams: Double? = nil
    var onConfirm: (Double) -> Void
    var onCancel: () -> Void
    
    @Query private var users: [User]
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    @State private var gramsText: String = ""
    
    private var inputAsGrams: Double {
        let raw = Double(gramsText) ?? 0
        switch unitSystem {
        case .metric: return raw
        case .imperial: return raw * 28.349523125
        }
    }
    private var calcCalories: Double { (caloriesPer100g / 100.0) * inputAsGrams }
    private var calcProtein: Double { (proteinPer100g / 100.0) * inputAsGrams }
    private var calcCarbs: Double { (carbsPer100g / 100.0) * inputAsGrams }
    private var calcFat: Double { (fatPer100g / 100.0) * inputAsGrams }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Adjust Serving")
                                        .font(.system(size: 24, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.3)
                                    
                                    Text(productName)
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.1)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Serving Size Input
                        VStack(spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "scalemass")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Serving Size")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    TextField("Enter amount", text: $gramsText)
                                        .keyboardType(.decimalPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.1)
                                    
                                    Text(unitSystem == .metric ? "g" : "oz")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.adaptiveSurface())
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Calculated Nutrition
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Calculated Nutrition")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            // Nutrition Card
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                    
                                    Text("Per Serving")
                                        .font(.system(size: 14, weight: .semibold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.2)
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(String(format: "%.0f", calcCalories))")
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(-0.5)
                                        
                                        Text("kcal")
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .kerning(0.3)
                                        
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 16) {
                                        MacroItem(name: "P", value: calcProtein, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                        MacroItem(name: "C", value: calcCarbs, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 0.3, green: 1.0, blue: 0.5))
                                        MacroItem(name: "F", value: calcFat, unit: unitSystem == .imperial ? "oz" : "g", color: Color(red: 1.0, green: 0.7, blue: 0.2))
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(DesignSystem.Colors.adaptiveCardBackground())
                                    .shadow(
                                        color: .black.opacity(0.08),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                onConfirm(inputAsGrams)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Add Food")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: DesignSystem.Colors.accent.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .disabled((Double(gramsText) ?? 0) <= 0)
                            
                            Button(action: {
                                onCancel()
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let g = initialGrams, gramsText.isEmpty {
                    let display = unitSystem == .metric ? g : (g / 28.349523125)
                    gramsText = String(format: display.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", display)
                }
            }
        }
    }
}

private struct MacroItem: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundColor(color)
                .kerning(0.5)
            
            Text("\(String(format: "%.1f", value))")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(-0.3)
            
            Text(unit)
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                .kerning(0.2)
        }
        .frame(maxWidth: .infinity)
    }
}
