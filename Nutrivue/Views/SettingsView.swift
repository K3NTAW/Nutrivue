import SwiftUI
import SwiftData

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
                    if viewModel.isHealthKitAuthorized {
                        Text("Apple Health Connected")
                            .foregroundColor(.green)
                        Text("Syncs automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Connect to Apple Health") {
                            viewModel.authorizeHealthKit()
                        }
                    }
                }
                
                if viewModel.isHealthKitAuthorized {
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
                        
                        TextField("Dietary Notes", text: $dietaryNotes)
                        
                        Button("Save Preferences") {
                            savePreferences()
                        }
                    }
                    
                    Section(header: Text("Goals")) {
                        if let goals = user?.goals {
                            Picker("Goal", selection: Binding(get: {
                                GoalService.GoalType(rawValue: goals.goalTypeRaw ?? "maintain") ?? .maintain
                            }, set: { newValue in
                                recalculateGoals(goal: newValue)
                            })) {
                                Text("Maintain").tag(GoalService.GoalType.maintain)
                                Text("Lose Weight").tag(GoalService.GoalType.lose)
                                Text("Gain Weight").tag(GoalService.GoalType.gain)
                                Text("Build Muscle").tag(GoalService.GoalType.muscle)
                            }
                            .pickerStyle(.menu)
                            HStack { Text("Calories"); Spacer(); Text(String(format: "%.0f kcal", goals.calories)) }
                            HStack { Text("Protein"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.protein, unitSystem: unitSystem)) }
                            HStack { Text("Carbs"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.carbohydrates, unitSystem: unitSystem)) }
                            HStack { Text("Fat"); Spacer(); Text(MassUnitFormatter.formatMacro(grams: goals.fat, unitSystem: unitSystem)) }
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
            .onChange(of: viewModel.isHealthKitAuthorized) { newValue in
                if newValue {
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
    
    private func savePreferences() {
        if let user = user {
            user.unitSystem = unitSystem
            user.dietaryNotes = dietaryNotes
            showingSaveConfirmation = true
            WidgetSnapshotService(modelContext: modelContext).writeSnapshot()
        }
    }
    
    private func recalculateGoals(goal: GoalService.GoalType) {
        guard let user = user else { return }
        let service = GoalService()
        let newGoals = service.calculateGoals(for: user, goal: goal)
        user.goals = newGoals
        WidgetSnapshotService(modelContext: modelContext).writeSnapshot()
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    return SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
}
