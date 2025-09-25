import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    private var user: User? { users.first }
    
    @StateObject var viewModel: SettingsViewModel
    
    @State private var unitSystem: UnitSystem = .metric
    @State private var dietaryNotes: String = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Integrations")) {
                    let connected = viewModel.isHealthKitAuthorized && viewModel.healthIntegrationEnabled
                    HealthStatusBanner(isConnected: connected)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    if connected {
                        Button("Disconnect Apple Health") {
                            viewModel.disableHealthIntegration()
                        }
                    } else {
                        Button("Connect to Apple Health") {
                            viewModel.enableHealthIntegration()
                            viewModel.authorizeHealthKit()
                        }
                    }
                }
                
                if viewModel.isHealthKitAuthorized && viewModel.healthIntegrationEnabled {
                    Section(header: Text("Health Data")) {
                        if let weight = viewModel.userWeight {
                            HStack {
                                Text("Latest Weight")
                                Spacer()
                                Text(formatWeight(weight))
                            }
                        }
                        
                        if let energy = viewModel.activeEnergy {
                            HStack {
                                Text("Active Energy Today")
                                Spacer()
                                Text("\(energy, specifier: "%.0f") kcal")
                            }
                        }
                    }
                }
                
                if user != nil {
                    Section(header: Text("Preferences")) {
                        Picker("Units", selection: $unitSystem) {
                            ForEach(UnitSystem.allCases, id: \.self) { system in
                                Text(system.rawValue.capitalized).tag(system)
                            }
                        }
                        .onChange(of: unitSystem) {
                            if let user = user {
                                user.unitSystem = unitSystem
                            }
                        }
                        
                        TextField("Dietary Notes", text: $dietaryNotes)
                            .onChange(of: dietaryNotes) {
                                if let user = user {
                                    user.dietaryNotes = dietaryNotes
                                }
                            }
                    }
                    
                    Section(header: Text("Goals")) {
                        if let goals = user?.goals {
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
                            if (goals.goalTypeRaw == "custom") {
                                HStack {
                                    Text("Calories"); Spacer()
                                    HStack(spacing: 6) {
                                        TextField("0", value: Binding(get: { goals.calories }, set: { goals.calories = $0 }), format: .number.precision(.fractionLength(0)))
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                        Text("kcal").foregroundColor(.secondary)
                                    }
                                }
                                HStack {
                                    Text("Protein"); Spacer()
                                    HStack(spacing: 6) {
                                        TextField("0", value: Binding(get: { goals.protein }, set: { goals.protein = $0 }), format: .number.precision(.fractionLength(0...1)))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                        Text("g").foregroundColor(.secondary)
                                    }
                                }
                                HStack {
                                    Text("Carbs"); Spacer()
                                    HStack(spacing: 6) {
                                        TextField("0", value: Binding(get: { goals.carbohydrates }, set: { goals.carbohydrates = $0 }), format: .number.precision(.fractionLength(0...1)))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                        Text("g").foregroundColor(.secondary)
                                    }
                                }
                                HStack {
                                    Text("Fat"); Spacer()
                                    HStack(spacing: 6) {
                                        TextField("0", value: Binding(get: { goals.fat }, set: { goals.fat = $0 }), format: .number.precision(.fractionLength(0...1)))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                        Text("g").foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                HStack { Text("Calories"); Spacer(); Text(String(format: "%.0f kcal", goals.calories)) }
                                HStack { Text("Protein"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.protein, unitSystem: unitSystem)) }
                                HStack { Text("Carbs"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.carbohydrates, unitSystem: unitSystem)) }
                                HStack { Text("Fat"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.fat, unitSystem: unitSystem)) }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Meal Reminders", isOn: $viewModel.notificationsEnabled)
                    
                    if viewModel.notificationsEnabled {
                        DatePicker("Breakfast Time", selection: $viewModel.breakfastReminderTime, displayedComponents: .hourAndMinute)
                        DatePicker("Lunch Time", selection: $viewModel.lunchReminderTime, displayedComponents: .hourAndMinute)
                        DatePicker("Dinner Time", selection: $viewModel.dinnerReminderTime, displayedComponents: .hourAndMinute)
                        
                        Button("Save Reminders") {
                            viewModel.scheduleReminders()
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
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
        }
    }
    
    private func loadUserData() {
        if let user = user {
            unitSystem = user.unitSystem
            dietaryNotes = user.dietaryNotes
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
        HStack(spacing: 12) {
            Image(systemName: isConnected ? "heart.fill" : "heart.slash")
                .foregroundColor(isConnected ? .green : .red)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 2) {
                Text(isConnected ? "Apple Health Connected" : "Apple Health Disconnected")
                    .font(.subheadline).fontWeight(.semibold)
                Text(isConnected ? "Syncs automatically" : "Connect to sync health data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    return SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
}
