import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @Query(sort: \Meal.date) private var meals: [Meal]
    @Query private var supplements: [Supplement]
    @Query private var waterIntakes: [WaterIntake]
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var totalCaloriesToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
    }
    
    private var totalFoodItemsToday: Int {
        todaysMeals.flatMap { $0.items }.count
    }
    
    private var totalProteinToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbsToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.carbohydrates }
    }
    
    private var totalFatToday: Double {
        todaysMeals.flatMap { $0.items }.reduce(0) { $0 + $1.fat }
    }
    
    private var totalWaterToday: Double {
        WaterIntake.totalToday(intakes: waterIntakes)
    }
    
    private var waterGoal: Double {
        2000.0 // 2 liters default goal
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
            ScrollView {
                    VStack(spacing: 32) {
                        // Header with greeting (Ultrahuman style)
                        VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .kerning(-0.3)
                            
                            Text("Track your nutrition journey")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.85))
                                .kerning(0.1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    if let user, let goals = user.goals {
                        
                            // Calorie Score Card (Ultrahuman style)
                            VStack(spacing: 0) {
                                let progress = totalCaloriesToday / goals.calories
                                
                                // Card Header
                                VStack(spacing: 0) {
                                    // Title and score
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Calorie Score")
                                                .font(.system(size: 18, weight: .semibold, design: .default))
                                                .foregroundColor(.white)
                                                .kerning(0.3)
                                            
                                            Text("\(String(format: "%.0f", totalCaloriesToday))")
                                                .font(.system(size: 64, weight: .bold, design: .default))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                                .kerning(-1.5)
                                        }
                                        
                                        Spacer()
                                        
                                        // Circular progress indicator
                        ZStack {
                                            // Background ring
                                            Circle()
                                                .stroke(.white.opacity(0.25), lineWidth: 8)
                                                .frame(width: 100, height: 100)
                                            
                                            // Progress ring
                                            Circle()
                                                .trim(from: 0, to: min(progress, 1.0))
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.white, .white.opacity(0.9)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                                )
                                                .frame(width: 100, height: 100)
                                                .rotationEffect(.degrees(-90))
                                                .animation(.easeInOut(duration: 1.2), value: progress)
                                            
                                            // Center text
                                            VStack(spacing: 2) {
                                                Text("\(String(format: "%.0f", progress * 100))%")
                                                    .font(.system(size: 14, weight: .bold, design: .default))
                                                    .foregroundColor(.white)
                                                
                                                Text("of goal")
                                                    .font(.system(size: 10, weight: .medium, design: .default))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 24)
                                    
                                    // Insight section
                                    VStack(spacing: 10) {
                                        if progress > 1.0 {
                                            Text("Goal Exceeded!")
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                                .foregroundColor(.white)
                                                .kerning(0.2)
                                            
                                            Text("You've surpassed your daily calorie goal. Great work!")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(.white.opacity(0.9))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .kerning(0.05)
                                        } else if progress > 0.8 {
                                            Text("Almost There!")
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                                .foregroundColor(.white)
                                                .kerning(0.2)
                                            
                                            Text("You're close to reaching your daily goal. Keep it up!")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(.white.opacity(0.9))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .kerning(0.05)
                                        } else {
                                            Text("Track Your Meals")
                                                .font(.system(size: 20, weight: .bold, design: .default))
                                                .foregroundColor(.white)
                                                .kerning(0.2)
                                            
                                            Text("Log your meals to reach your daily calorie goal.")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(.white.opacity(0.9))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .kerning(0.05)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 24)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.4, blue: 0.6),
                                                Color(red: 0.0, green: 0.5, blue: 0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.6).opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                            .padding(.horizontal, 20)
                            
                            // Macronutrients Card (Ultrahuman style)
                            VStack(spacing: 0) {
                                // Card Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                            Text("Macronutrients")
                                            .font(.system(size: 18, weight: .semibold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(0.3)
                                        
                                        Text("Daily intake breakdown")
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(.white.opacity(0.85))
                                            .kerning(0.1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Total calories indicator
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(String(format: "%.0f", totalCaloriesToday))")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(-0.5)
                                        
                                        Text("kcal")
                                            .font(.system(size: 12, weight: .regular, design: .default))
                                            .foregroundColor(.white.opacity(0.7))
                                            .kerning(0.5)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                
                                // Macro items
                                VStack(spacing: 20) {
                                    MacroItemView(
                                        name: "Protein",
                                        current: totalProteinToday,
                                        goal: goals.protein,
                                        unit: "g",
                                        color: Color(red: 0.4, green: 0.8, blue: 1.0)
                                    )
                                    
                                    MacroItemView(
                                        name: "Carbs",
                                        current: totalCarbsToday,
                                        goal: goals.carbohydrates,
                                        unit: "g",
                                        color: Color(red: 0.3, green: 1.0, blue: 0.5)
                                    )
                                    
                                    MacroItemView(
                                        name: "Fat",
                                        current: totalFatToday,
                                        goal: goals.fat,
                                        unit: "g",
                                        color: Color(red: 1.0, green: 0.7, blue: 0.2)
                                    )
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.1, green: 0.5, blue: 0.3),
                                                Color(red: 0.0, green: 0.6, blue: 0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(red: 0.1, green: 0.5, blue: 0.3).opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                            .padding(.horizontal, 20)
                            
                            // Water Tracking Card (Ultrahuman style)
                            VStack(spacing: 0) {
                                // Card Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Hydration")
                                            .font(.system(size: 18, weight: .semibold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(0.3)
                                        
                                        Text("Daily water intake")
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(.white.opacity(0.85))
                                            .kerning(0.1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Water amount indicator
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(String(format: "%.0f", totalWaterToday))")
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(-0.5)
                                        
                                        Text("ml")
                                            .font(.system(size: 12, weight: .regular, design: .default))
                                            .foregroundColor(.white.opacity(0.7))
                                            .kerning(0.5)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                
                                // Quick Add Buttons with better spacing
                                VStack(spacing: 12) {
                                    HStack(spacing: 0) {
                                        Button(action: {
                                            addWater(amount: 250)
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("250")
                                                    .font(.system(size: 16, weight: .bold, design: .default))
                                                    .foregroundColor(.white)
                                                    .kerning(-0.2)
                                                
                                                Text("ml")
                                                    .font(.system(size: 10, weight: .medium, design: .default))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .kerning(0.3)
                                            }
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.white.opacity(0.15))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                        
                                        Spacer()
                                            .frame(width: 12)
                                        
                                        Button(action: {
                                            addWater(amount: 500)
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("500")
                                                    .font(.system(size: 16, weight: .bold, design: .default))
                                                    .foregroundColor(.white)
                                                    .kerning(-0.2)
                                                
                                                Text("ml")
                                                    .font(.system(size: 10, weight: .medium, design: .default))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .kerning(0.3)
                                            }
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.white.opacity(0.15))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                        
                                        Spacer()
                                            .frame(width: 12)
                                        
                                        Button(action: {
                                            addWater(amount: 1000)
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("1L")
                                                    .font(.system(size: 16, weight: .bold, design: .default))
                                                    .foregroundColor(.white)
                                                    .kerning(-0.2)
                                                
                                                Text("liter")
                                                    .font(.system(size: 10, weight: .medium, design: .default))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .kerning(0.3)
                                            }
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.white.opacity(0.15))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                    .padding(.top, 16)
                                    
                                    // Progress text and bar with better styling
                        VStack(spacing: 12) {
                                        Text("\(String(format: "%.0f", totalWaterToday)) of \(String(format: "%.0f", waterGoal)) ml")
                                            .font(.system(size: 14, weight: .semibold, design: .default))
                                            .foregroundColor(.white.opacity(0.9))
                                            .kerning(0.1)
                                        
                                        // Enhanced progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.white.opacity(0.15))
                                                    .frame(height: 10)
                                                
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.white, .cyan.opacity(0.9)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: geometry.size.width * min(totalWaterToday / waterGoal, 1.0), height: 10)
                                                    .animation(.easeInOut(duration: 1.0), value: totalWaterToday)
                                                
                                                // Progress percentage overlay
                                                if totalWaterToday > 0 {
                                                    HStack {
                                                        Spacer()
                                                        Text("\(String(format: "%.0f", (totalWaterToday / waterGoal) * 100))%")
                                                            .font(.system(size: 10, weight: .bold, design: .default))
                                                            .foregroundColor(.white.opacity(0.8))
                                                            .kerning(0.2)
                                                            .padding(.trailing, 8)
                                                    }
                                                }
                                            }
                                        }
                                        .frame(height: 10)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.4, blue: 0.8),
                                                Color(red: 0.0, green: 0.6, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                            .padding(.horizontal, 20)
                            
                            // Supplements Card (Ultrahuman style)
                            VStack(spacing: 0) {
                                // Card Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Supplements Today")
                                            .font(.system(size: 18, weight: .semibold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(0.3)
                                        
                                        Text("Daily supplement schedule")
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(.white.opacity(0.85))
                                            .kerning(0.1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Count indicator
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(supplementsForToday.count)")
                                            .font(.system(size: 20, weight: .bold, design: .default))
                                            .foregroundColor(.white)
                                            .kerning(-0.5)
                                        
                                        Text("items")
                                            .font(.system(size: 12, weight: .regular, design: .default))
                                            .foregroundColor(.white.opacity(0.7))
                                            .kerning(0.5)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                                
                                if supplementsForToday.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "capsule")
                                            .font(.system(size: 40, weight: .regular))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text("No supplements scheduled today")
                                            .font(.system(size: 16, weight: .regular, design: .default))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .kerning(0.2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(supplementsForToday) { supp in
                                        SupplementItemView(supplement: supp)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .padding(.bottom, 24)
                            }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.6, green: 0.3, blue: 0.1),
                                                Color(red: 0.7, green: 0.4, blue: 0.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color(red: 0.6, green: 0.3, blue: 0.1).opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                            .padding(.horizontal, 20)
                            
                        } else {
                            // Onboarding state
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(DesignSystem.Colors.accent)
                                
                                Text("Welcome to Nourivo")
                                    .font(DesignSystem.Typography.title1)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Text("Complete onboarding to start tracking your nutrition journey")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .multilineTextAlignment(.center)
                                
                                Button("Get Started") {
                                    // TODO: Navigate to onboarding
                                }
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(
                                    Capsule()
                                        .fill(DesignSystem.Colors.accent)
                                )
                            }
                            .padding(DesignSystem.Spacing.xl)
                            .dataCardStyle()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                    .id(totalFoodItemsToday)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
        }
    }
}

private extension DashboardView {
    var supplementsForToday: [Supplement] {
        supplements.filter { $0.isScheduledForToday() }
    }
    
    func addWater(amount: Double) {
        let intake = WaterIntake(amount: amount)
        modelContext.insert(intake)
    }
}

private struct SupplementCard: View {
    @Environment(\.modelContext) private var modelContext
    let supplement: Supplement
    @State private var isTaken: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Icon with status (Ultrahuman style)
            ZStack {
                Circle()
                    .fill(
                        isTaken ? 
                        .white.opacity(0.2) : 
                        .white.opacity(0.1)
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: isTaken ? "checkmark" : "capsule")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(supplement.name)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let dosage = supplement.dosage, !dosage.isEmpty {
                        ChipView(icon: "pills", text: dosage)
                    }
                    if let t = supplement.timeComponents(), let hour = t.hour, let minute = t.minute {
                        ChipView(icon: "clock", text: String(format: "%02d:%02d", hour, minute))
                    }
                }
            }
            
            Spacer(minLength: DesignSystem.Spacing.sm)
            
            // Action button (Ultrahuman style)
            Button(action: { 
                withAnimation(DesignSystem.Animation.standard) { 
                    toggleTaken() 
                } 
            }) {
                ZStack {
                    Circle()
                        .fill(
                            isTaken ? 
                            .white : 
                            .white.opacity(0.2)
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: isTaken ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isTaken ? .black : .white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isTaken ? "Marked taken" : "Mark as taken")
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(.white.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .onAppear { isTaken = supplement.wasTakenToday() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityStringBuilder.describe(supplement: supplement, isTaken: isTaken))
    }
    
    private func toggleTaken() {
        if isTaken { return }
        let intake = SupplementIntake(supplementID: supplement.id, date: Date())
        supplement.intakes.append(intake)
        isTaken = true
    }
}

private struct ChipView: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption2)
            Text(text)
                .font(DesignSystem.Typography.caption2)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(.white.opacity(0.2))
        )
        .foregroundColor(.white.opacity(0.8))
    }
}

private struct SupplementItemView: View {
    @Environment(\.modelContext) private var modelContext
    let supplement: Supplement
    @State private var isTaken: Bool = false
    
    var body: some View {
        Button(action: { 
            withAnimation(.easeInOut(duration: 0.4)) { 
                toggleTaken() 
            } 
        }) {
            HStack(spacing: 20) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(isTaken ? .white.opacity(0.25) : .white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isTaken ? "checkmark" : "capsule")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(supplement.name)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .kerning(0.2)
                    
                    HStack(spacing: 12) {
                        if let dosage = supplement.dosage, !dosage.isEmpty {
                            Text(dosage)
                                .font(.system(size: 15, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .kerning(0.1)
                        }
                        
                        if let t = supplement.timeComponents(), let hour = t.hour, let minute = t.minute {
                            Text(String(format: "%02d:%02d", hour, minute))
                                .font(.system(size: 15, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .kerning(0.1)
                        }
                    }
                }
                
                Spacer()
                
                // Action indicator
                ZStack {
                    Circle()
                        .fill(isTaken ? .white : .white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: isTaken ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isTaken ? .black : .white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .onAppear { isTaken = supplement.wasTakenToday() }
    }
    
    private func toggleTaken() {
        if isTaken { return }
        let intake = SupplementIntake(supplementID: supplement.id, date: Date())
        supplement.intakes.append(intake)
        isTaken = true
    }
}

private struct MacroItemView: View {
    let name: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(current / goal, 1.0)
    }
    
    private var overflow: Double {
        max(0, current - goal)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Macro name and values
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .kerning(0.2)
                
                HStack(spacing: 6) {
                    Text("\(String(format: "%.0f", current))")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .kerning(-0.5)
                    
                    Text(unit)
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.85))
                        .kerning(0.3)
                    
                    Text("of \(String(format: "%.0f", goal))")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.75))
                        .kerning(0.2)
                }
            }
            
            Spacer()
            
            // Progress indicator with percentage
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(String(format: "%.0f", progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .kerning(0.2)
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.15))
                        .frame(width: 80, height: 10)
                    
                    // Progress with brighter colors
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(progress) * 80, height: 10)
                        .animation(.easeInOut(duration: 1.0), value: progress)
                    
                    // Overflow
                    if overflow > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(CGFloat(overflow / goal) * 80, 20), height: 10)
                            .animation(.easeInOut(duration: 1.0), value: overflow)
                    }
                    
                    // Border on top
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 80, height: 10)
                }
            }
        }
    }
}

private enum AccessibilityStringBuilder {
    static func describe(supplement: Supplement, isTaken: Bool) -> String {
        var parts: [String] = [supplement.name]
        if let dosage = supplement.dosage, !dosage.isEmpty { parts.append(dosage) }
        if let t = supplement.timeComponents(), let h = t.hour, let m = t.minute {
            parts.append(String(format: "%02d:%02d", h, m))
        }
        parts.append(isTaken ? "Taken" : "Not taken")
        return parts.joined(separator: ", ")
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MON d MMM"
        return formatter
    }()
}

#Preview {
    DashboardView()
}
