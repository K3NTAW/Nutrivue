import SwiftUI
import SwiftData

struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]
    var onPick: (Recipe) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pick Recipe")
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.5)
                                    
                                    Text("Choose a recipe to add")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .opacity(0.85)
                                        .kerning(0.1)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 24)
                        
                        // Recipes List
                        LazyVStack(spacing: 12) {
                            ForEach(recipes) { recipe in
                                Button {
                                    onPick(recipe)
                                    dismiss()
                                } label: {
                                    RecipePickerCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Cancel") { onCancel(); dismiss() } 
                }
            }
        }
    }
}

private struct RecipePickerCard: View {
    let recipe: Recipe
    
    private var perServingNutrition: (cal: Double, p: Double, c: Double, f: Double) {
        recipe.perServingNutrition()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Recipe Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.2),
                                DesignSystem.Colors.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .frame(width: 56, height: 56)
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.2)
                    .lineLimit(2)
                
                if recipe.servings > 0 {
                    Text("\(String(format: "%.1f", recipe.servings)) servings")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                        .kerning(0.1)
                }
            }
            
            Spacer()
            
            // Nutrition Info
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.0f", perServingNutrition.cal))")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(-0.5)
                
                Text("kcal/serv")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    }
}

struct AdjustRecipeServingsView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var servings: Double
    var onConfirm: (Double) -> Void
    
    init(recipe: Recipe, defaultServings: Double, onConfirm: @escaping (Double) -> Void) {
        self.recipe = recipe
        _servings = State(initialValue: max(0.1, defaultServings))
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.accent.opacity(0.2),
                                                DesignSystem.Colors.accent.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Adjust Servings")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.5)
                                
                                Text(recipe.name)
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .opacity(0.85)
                                    .kerning(0.1)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Servings Control
                        VStack(spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "person.2")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Servings")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                // Servings Stepper
                                HStack {
                                    Stepper(value: $servings, in: 0.1...50, step: 0.5) {
                                        Text("\(String(format: "%.1f", servings)) servings")
                                            .font(.system(size: 18, weight: .semibold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(0.1)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.adaptiveSurface())
                                )
                                
                                // Nutrition Display
                                let n = recipe.scaledNutrition(servings: servings)
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
                                            Text("\(String(format: "%.0f", n.cal))")
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
                                            MacroItem(name: "P", value: n.p, unit: "g", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                                            MacroItem(name: "C", value: n.c, unit: "g", color: Color(red: 0.3, green: 1.0, blue: 0.5))
                                            MacroItem(name: "F", value: n.f, unit: "g", color: Color(red: 1.0, green: 0.7, blue: 0.2))
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
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                onConfirm(servings)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Add Recipe")
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
                            
                            Button(action: {
                                dismiss()
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


