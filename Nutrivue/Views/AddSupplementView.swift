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
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    TextField("Dosage (optional)", text: $dosage)
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section(header: Text("Schedule")) {
                    Picker("Frequency", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch scheduleType {
                    case .daily:
                        EmptyView()
                    case .weekly:
                        // Allow selecting one or many weekdays
                        WeekdaySelector(selected: $selectedWeekdays)
                    }
                    
                    DatePicker("Time of Day (optional)", selection: $timeOfDay, displayedComponents: .hourAndMinute)
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

private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let symbols = Calendar.current.weekdaySymbols
    // Sunday=1 ... Saturday=7
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(1...7, id: \.self) { idx in
                let isOn = selected.contains(idx)
                Button(action: {
                    if isOn { selected.remove(idx) } else { selected.insert(idx) }
                }) {
                    HStack {
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        Text(symbols[idx - 1])
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}


