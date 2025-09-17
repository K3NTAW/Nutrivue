import SwiftUI
import SwiftData

struct SettingsView: View {
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
                        
                        Button("Sync Health Data") {
                            viewModel.fetchHealthData()
                        }
                        
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
                                Text("\(weight, specifier: "%.1f") kg")
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
                
                if let user = user {
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
            .onAppear(perform: loadUserData)
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
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    return SettingsView(viewModel: SettingsViewModel(modelContext: container.mainContext))
}
