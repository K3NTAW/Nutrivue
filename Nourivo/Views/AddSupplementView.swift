import SwiftUI
import SwiftData
import WidgetKit

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var notes: String = ""
    @State private var scheduleType: ScheduleType = .daily
    @State private var selectedWeekdays: Set<Int> = []
    @State private var monthlyDay: Int = 1 // deprecated (kept to avoid breaking previews)
    @State private var timeOfDay: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    private enum ScheduleType: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly" // one or multiple weekdays
        var id: String { rawValue }
    }
    
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
                            Image(systemName: "pills.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("Track your daily supplements and vitamins")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // Details Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Details")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                SupplementInputField(title: "Name", text: $name, placeholder: "e.g., Vitamin D3")
                                SupplementInputField(title: "Dosage (optional)", text: $dosage, placeholder: "e.g., 1000 IU")
                                SupplementInputField(title: "Notes (optional)", text: $notes, placeholder: "e.g., Take with food")
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Schedule Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Schedule")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                // Frequency Picker
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Frequency")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    
                                    Picker("Frequency", selection: $scheduleType) {
                                        ForEach(ScheduleType.allCases) { t in
                                            Text(t.rawValue).tag(t)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.md)
                                .metricCardStyle()
                                
                                // Weekly Schedule
                                if scheduleType == .weekly {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Select Days")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        
                                        WeekdaySelector(selected: $selectedWeekdays)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.Spacing.md)
                                    .metricCardStyle()
                                }
                                
                                // Time Picker
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Time of Day")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    
                                    DatePicker("Time of Day (optional)", selection: $timeOfDay, displayedComponents: .hourAndMinute)
                                        .font(DesignSystem.Typography.subheadline)
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.md)
                                .metricCardStyle()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                }
            }
            .navigationTitle("Add Supplement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: timeOfDay)
        let scheduleTypePersist: SupplementScheduleType
        var specificDaysMaskPersist: Int? = nil
        var weeklyPersist: Int? = nil
        switch scheduleType {
        case .daily:
            scheduleTypePersist = .daily
        case .weekly:
            let days = Array(selectedWeekdays).sorted()
            if days.count <= 1 {
                scheduleTypePersist = .weekly
                weeklyPersist = days.first ?? 2 // default Monday
            } else {
                scheduleTypePersist = .specificDays
                var mask = 0
                for d in days { mask |= (1 << (d - 1)) }
                specificDaysMaskPersist = mask
            }
        }
        let supplement = Supplement(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : dosage,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            scheduleType: scheduleTypePersist,
            specificDaysMask: specificDaysMaskPersist,
            weeklyWeekday: weeklyPersist,
            timeHour: comps.hour,
            timeMinute: comps.minute
        )
        modelContext.insert(supplement)
        NotificationService().scheduleSupplementReminder(for: supplement)
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
        dismiss()
    }
}

// MARK: - Helper Views
private struct SupplementInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
            
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .metricCardStyle()
    }
}

private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let symbols = Calendar.current.weekdaySymbols
    // Sunday=1 ... Saturday=7
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(1...7, id: \.self) { idx in
                let isOn = selected.contains(idx)
                Button(action: {
                    if isOn { selected.remove(idx) } else { selected.insert(idx) }
                }) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isOn ? DesignSystem.Colors.accent : DesignSystem.Colors.adaptiveSecondaryText())
                            .font(.title3)
                        
                        Text(symbols[idx - 1])
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(isOn ? DesignSystem.Colors.accent : DesignSystem.Colors.adaptiveSecondaryText())
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(isOn ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Colors.adaptiveSurface().opacity(0.5))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}


