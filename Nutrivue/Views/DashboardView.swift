import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @Query(sort: \Meal.date) private var meals: [Meal]
    @Query private var supplements: [Supplement]
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    Text(greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let user, let goals = user.goals {
                        
                        // Calorie Progress Ring
                        ZStack {
                            ProgressRingView(progress: totalCaloriesToday / goals.calories, color: .accentColor)
                                .frame(width: 220, height: 220)
                            
                            VStack {
                                Text("\(totalCaloriesToday, specifier: "%.0f")")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("kcal consumed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 20)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Calorie Intake")
                        .accessibilityValue("\(totalCaloriesToday, specifier: "%.0f") of \(goals.calories, specifier: "%.0f") kcal")
                        
                        // Macronutrient Progress Bars
                        GroupBox {
                            VStack(spacing: 15) {
                                MacroProgressView(name: "Protein", current: totalProteinToday, goal: goals.protein, color: .red)
                                MacroProgressView(name: "Carbs", current: totalCarbsToday, goal: goals.carbohydrates, color: .green)
                                MacroProgressView(name: "Fat", current: totalFatToday, goal: goals.fat, color: .orange)
                            }
                        } label: {
                            Text("Macronutrients")
                                .font(.headline)
                        }
                        
                    } else {
                        Text("No user data found. Complete onboarding to see your dashboard.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Supplements Today
                    GroupBox {
                        VStack(spacing: 12) {
                            if supplementsForToday.isEmpty {
                                HStack {
                                    Image(systemName: "capsule")
                                        .foregroundColor(.secondary)
                                    Text("No supplements scheduled today")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            } else {
                                ForEach(supplementsForToday) { supp in
                                    SupplementCard(supplement: supp)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "pills")
                            Text("Supplements Today")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
                .id(totalFoodItemsToday)
                .padding()
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
}

private struct SupplementCard: View {
    @Environment(\.modelContext) private var modelContext
    let supplement: Supplement
    @State private var isTaken: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isTaken ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: isTaken ? "checkmark" : "capsule")
                    .foregroundColor(isTaken ? .green : .accentColor)
                    .imageScale(.medium)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(supplement.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    if let dosage = supplement.dosage, !dosage.isEmpty {
                        ChipView(icon: "pills", text: dosage)
                    }
                    if let t = supplement.timeComponents(), let hour = t.hour, let minute = t.minute {
                        ChipView(icon: "clock", text: String(format: "%02d:%02d", hour, minute))
                    }
                }
            }
            Spacer(minLength: 12)
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { toggleTaken() } }) {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isTaken ? .green : Color(.tertiaryLabel))
                    .accessibilityLabel(isTaken ? "Marked taken" : "Mark as taken")
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color(.tertiarySystemFill))
        )
        .foregroundStyle(.secondary)
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

#Preview {
    DashboardView()
}
