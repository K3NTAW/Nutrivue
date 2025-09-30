import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showOnboarding: Bool
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: Gender = .male
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var goalType: GoalService.GoalType = .maintain
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("Welcome to Nourivo")
                                .font(DesignSystem.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                            
                            Text("Let's set up your profile to get personalized nutrition recommendations")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // Personal Information
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Personal Information")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                OnboardingInputField(title: "Age", text: $age, placeholder: "25", keyboardType: .numberPad)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Gender")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    
                                    Picker("Gender", selection: $gender) {
                                        Text("Male").tag(Gender.male)
                                        Text("Female").tag(Gender.female)
                                    }
                                    .accessibilityIdentifier("gender_picker")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.md)
                                .metricCardStyle()
                                
                                OnboardingInputField(title: "Weight (kg)", text: $weight, placeholder: "70.0", keyboardType: .decimalPad)
                                OnboardingInputField(title: "Height (cm)", text: $height, placeholder: "175.0", keyboardType: .decimalPad)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Activity Level
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Activity Level")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Select Activity Level")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                
                                Picker("Select Activity Level", selection: $activityLevel) {
                                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                                        Text(level.rawValue.capitalized).tag(level)
                                    }
                                }
                                .accessibilityIdentifier("activity_level_picker")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.md)
                            .metricCardStyle()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Goal
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Goal")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Select Goal")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                
                                Picker("Select Goal", selection: $goalType) {
                                    Text("Maintain").tag(GoalService.GoalType.maintain)
                                    Text("Lose Weight").tag(GoalService.GoalType.lose)
                                    Text("Gain Weight").tag(GoalService.GoalType.gain)
                                    Text("Build Muscle").tag(GoalService.GoalType.muscle)
                                }
                                .pickerStyle(.inline)
                                .accessibilityIdentifier("goal_picker")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.md)
                            .metricCardStyle()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Save Button
                        Button(action: {
                            saveUser()
                        }) {
                            HStack {
                                Text("Save and Continue")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(DesignSystem.Colors.accent)
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.lg)
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
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
        let goals = goalService.calculateGoals(for: newUser, goal: goalType)
        newUser.goals = goals
        
        modelContext.insert(newUser)
        
        showOnboarding = false
    }
}

// MARK: - Helper Views
private struct OnboardingInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .metricCardStyle()
    }
}

#Preview {
    // Need to provide a dummy binding for the preview
    OnboardingView(showOnboarding: .constant(true))
}
