import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showOnboarding: Bool
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: Gender = .male
    @State private var activityLevel: ActivityLevel = .sedentary
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag(Gender.male)
                        Text("Female").tag(Gender.female)
                    }
                    .accessibilityIdentifier("gender_picker")
                    
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Select Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    .accessibilityIdentifier("activity_level_picker")
                }
                
                Button(action: {
                    saveUser()
                }) {
                    Text("Save and Continue")
                }
            }
            .navigationTitle("Tell us about you")
        }
    }
    
    private func saveUser() {
        guard let ageInt = Int(age),
              let weightDouble = Double(weight),
              let heightDouble = Double(height) else {
            // Handle invalid input - maybe show an alert
            print("Invalid input")
            return
        }
        
        let newUser = User(age: ageInt, gender: gender, weight: weightDouble, height: heightDouble, activityLevel: activityLevel, goals: nil, unitSystem: .metric, dietaryNotes: "")
        
        let goalService = GoalService()
        let goals = goalService.calculateGoals(for: newUser)
        newUser.goals = goals
        
        modelContext.insert(newUser)
        
        showOnboarding = false
    }
}

#Preview {
    // Need to provide a dummy binding for the preview
    OnboardingView(showOnboarding: .constant(true))
}
