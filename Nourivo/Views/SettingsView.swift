import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @StateObject var viewModel: SettingsViewModel
    
    @State private var unitSystem: UnitSystem = .metric
    @State private var showingSaveConfirmation = false
    @State private var showingReminderConfirmation = false
    
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
                                    Text("Settings")
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.3)
                                    
                                    Text("Customize your app experience")
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
                        
                        // Integrations Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Integrations")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            let connected = viewModel.isHealthKitAuthorized && viewModel.healthIntegrationEnabled
                            HealthStatusBanner(isConnected: connected)
                                .padding(.horizontal, 24)
                            
                            Button(action: {
                                if connected {
                                    viewModel.disableHealthIntegration()
                                } else {
                                    viewModel.enableHealthIntegration()
                                    viewModel.authorizeHealthKit()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: connected ? "heart.slash" : "heart.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text(connected ? "Disconnect Apple Health" : "Connect to Apple Health")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: connected ? [DesignSystem.Colors.error, DesignSystem.Colors.error.opacity(0.8)] : [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: (connected ? DesignSystem.Colors.error : DesignSystem.Colors.accent).opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Health Data Section
                        if viewModel.isHealthKitAuthorized && viewModel.healthIntegrationEnabled {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "heart.text.square")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    Text("Health Data")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    if let weight = viewModel.userWeight {
                                        HealthDataRow(title: "Latest Weight", value: formatWeight(weight))
                                    }
                                    
                                    if let energy = viewModel.activeEnergy {
                                        HealthDataRow(title: "Active Energy Today", value: String(format: "%.0f kcal", energy))
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Preferences Section
                        if user != nil {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    Text("Preferences")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    SettingsRow(title: "Units", content: {
                                        Picker("Units", selection: $unitSystem) {
                                            ForEach(UnitSystem.allCases, id: \.self) { system in
                                                Text(system.rawValue.capitalized).tag(system)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .onChange(of: unitSystem) {
                                            if let user = user {
                                                user.unitSystem = unitSystem
                                            }
                                        }
                                    })
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Goals Section
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "target")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    Text("Goals")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                if let goals = user?.goals {
                                    VStack(spacing: 12) {
                                        SettingsRow(title: "Goal Type", content: {
                                            Picker("Goal", selection: Binding(get: {
                                                GoalService.GoalType(rawValue: goals.goalTypeRaw ?? "maintain") ?? .maintain
                                            }, set: { newValue in
                                                if newValue == .custom {
                                                    goals.goalTypeRaw = "custom"
                                                } else {
                                                    recalculateGoals(goal: newValue)
                                                }
                                            })) {
                                                Text("Maintain").tag(GoalService.GoalType.maintain)
                                                Text("Lose Weight").tag(GoalService.GoalType.lose)
                                                Text("Gain Weight").tag(GoalService.GoalType.gain)
                                                Text("Build Muscle").tag(GoalService.GoalType.muscle)
                                                Text("Custom").tag(GoalService.GoalType(rawValue: "custom")!)
                                            }
                                            .pickerStyle(.menu)
                                        })
                                        
                                        // Combined Goals Card
                                        VStack(spacing: 12) {
                                            HStack {
                                                Text("Nutrition Goals")
                                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                    .kerning(0.2)
                                                
                                                Spacer()
                                            }
                                            
                                            if (goals.goalTypeRaw == "custom") {
                                                CustomGoalsView(goals: goals)
                                            } else {
                                                ReadOnlyGoalsView(goals: goals, unitSystem: unitSystem)
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
                            }
                        }
                        
                        // Notifications Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Notifications")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                SettingsRow(title: "Meal Reminders", content: {
                                    Toggle("", isOn: $viewModel.notificationsEnabled)
                                })
                                
                                if viewModel.notificationsEnabled {
                                    VStack(spacing: 12) {
                                        DatePicker("Breakfast Time", selection: $viewModel.breakfastReminderTime, displayedComponents: .hourAndMinute)
                                        DatePicker("Lunch Time", selection: $viewModel.lunchReminderTime, displayedComponents: .hourAndMinute)
                                        DatePicker("Dinner Time", selection: $viewModel.dinnerReminderTime, displayedComponents: .hourAndMinute)
                                        
                                        Button("Save Reminders") {
                                            viewModel.scheduleReminders()
                                            showingReminderConfirmation = true
                                        }
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .shadow(
                                                    color: DesignSystem.Colors.accent.opacity(0.3),
                                                    radius: 6,
                                                    x: 0,
                                                    y: 3
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            VStack {
                                Text(errorMessage)
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignSystem.Colors.error.opacity(0.1))
                                    )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadUserData()
                viewModel.refreshHealthKitAuthorizationState()
                if viewModel.isHealthKitAuthorized {
                    viewModel.fetchHealthData()
                }
            }
            .onChange(of: viewModel.isHealthKitAuthorized) {
                if viewModel.isHealthKitAuthorized {
                    viewModel.fetchHealthData()
                }
            }
            .alert("Preferences Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            }
            .alert("Reminders Saved", isPresented: $showingReminderConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your meal reminders have been scheduled successfully.")
            }
        }
    }
    
    private func loadUserData() {
        if let user = user {
            unitSystem = user.unitSystem
        }
    }
    
    private func savePreferences() { }
    
    private func recalculateGoals(goal: GoalService.GoalType) {
        guard let user = user else { return }
        let service = GoalService()
        let newGoals = service.calculateGoals(for: user, goal: goal)
        user.goals = newGoals
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
    }
    
    private func formatWeight(_ kilograms: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", kilograms)
        case .imperial:
            let pounds = kilograms * 2.2046226218
            return String(format: "%.1f lb", pounds)
        }
    }
}

private struct HealthStatusBanner: View {
    let isConnected: Bool
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isConnected ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.error.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: isConnected ? "heart.fill" : "heart.slash")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isConnected ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isConnected ? "Apple Health Connected" : "Apple Health Disconnected")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.2)
                
                Text(isConnected ? "Syncs automatically" : "Connect to sync health data")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.1)
                    .opacity(0.8)
            }
            
            Spacer()
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
}

private struct HealthDataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(0.1)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                .kerning(0.1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(0.1)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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

private struct CustomGoalsView: View {
    let goals: Goals
    
    var body: some View {
        VStack(spacing: 8) {
            GoalInputRow(title: "Calories", value: Binding(get: { goals.calories }, set: { goals.calories = $0 }), unit: "kcal")
            GoalInputRow(title: "Protein", value: Binding(get: { goals.protein }, set: { goals.protein = $0 }), unit: "g")
            GoalInputRow(title: "Carbs", value: Binding(get: { goals.carbohydrates }, set: { goals.carbohydrates = $0 }), unit: "g")
            GoalInputRow(title: "Fat", value: Binding(get: { goals.fat }, set: { goals.fat = $0 }), unit: "g")
        }
    }
}

private struct ReadOnlyGoalsView: View {
    let goals: Goals
    let unitSystem: UnitSystem
    
    var body: some View {
        VStack(spacing: 8) {
            GoalDisplayRow(title: "Calories", value: String(format: "%.0f kcal", goals.calories))
            GoalDisplayRow(title: "Protein", value: MassUnitFormatter.formatMacro(grams: goals.protein, unitSystem: unitSystem))
            GoalDisplayRow(title: "Carbs", value: MassUnitFormatter.formatMacro(grams: goals.carbohydrates, unitSystem: unitSystem))
            GoalDisplayRow(title: "Fat", value: MassUnitFormatter.formatMacro(grams: goals.fat, unitSystem: unitSystem))
        }
    }
}

private struct GoalInputRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(0.1)
            Spacer()
            HStack(spacing: 8) {
                TextField("0", value: $value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.1)
                Text(unit)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                    .kerning(0.1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.5))
        )
    }
}

private struct GoalDisplayRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                .kerning(0.1)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                .kerning(0.1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.5))
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    return SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
}
