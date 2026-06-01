import SwiftUI
import SwiftData

struct AddWaterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    @Binding var selectedAmount: Double
    
    @State private var customAmount: String = ""
    @State private var isCustomAmount = false
    
    private let waterAmounts = [100, 150, 200, 250, 300, 350, 400, 500]
    
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
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Water")
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.3)
                                    
                                    Text("Track your hydration")
                                        .font(.system(size: 17, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .opacity(0.85)
                                        .kerning(0.1)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Amount Selection
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "drop.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Amount")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            // Quick Amount Buttons
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                                ForEach(waterAmounts, id: \.self) { amount in
                                    Button(action: {
                                        selectedAmount = Double(amount)
                                        isCustomAmount = false
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("\(amount)")
                                                .font(.system(size: 16, weight: .bold, design: .default))
                                                .foregroundColor(selectedAmount == Double(amount) && !isCustomAmount ? .white : DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(-0.3)
                                            
                                            Text(unitSystem == .metric ? "ml" : "fl oz")
                                                .font(.system(size: 10, weight: .medium, design: .default))
                                                .foregroundColor(selectedAmount == Double(amount) && !isCustomAmount ? .white.opacity(0.8) : DesignSystem.Colors.adaptiveSecondaryText())
                                                .kerning(0.2)
                                        }
                                        .frame(width: 60, height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedAmount == Double(amount) && !isCustomAmount ? 
                                                    LinearGradient(colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                                    LinearGradient(colors: [DesignSystem.Colors.adaptiveCardBackground()], startPoint: .leading, endPoint: .trailing)
                                                )
                                                .shadow(
                                                    color: .black.opacity(0.08),
                                                    radius: 6,
                                                    x: 0,
                                                    y: 3
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Custom Amount
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Custom Amount")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.2)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    TextField("Enter amount", text: $customAmount)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.1)
                                        .multilineTextAlignment(.trailing)
                                    
                                    Text(unitSystem == .metric ? "ml" : "fl oz")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .kerning(0.2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.adaptiveSurface())
                                )
                                .onChange(of: customAmount) { _, newValue in
                                    if let amount = Double(newValue), amount > 0 {
                                        selectedAmount = amount
                                        isCustomAmount = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                addWater()
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Add Water")
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
    
    private func addWater() {
        let amount = isCustomAmount ? (Double(customAmount) ?? selectedAmount) : selectedAmount
        let intake = WaterIntake(amount: amount)
        modelContext.insert(intake)
    }
}

#Preview {
    AddWaterView(selectedAmount: .constant(250))
}
