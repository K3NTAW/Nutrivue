import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @State private var showingAddSupplement = false
    @State private var searchQuery = ""
    
    private var filteredSupplements: [Supplement] {
        if searchQuery.isEmpty {
            return supplements
        } else {
            return supplements.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSupplements) { supp in
                    NavigationLink(destination: EditSupplementView(supplement: supp)) {
                        SupplementRowView(supplement: supp)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            toggleTakenToday(for: supp)
                        } label: {
                            Label(supp.wasTakenToday() ? "Unmark" : "Mark Taken", systemImage: supp.wasTakenToday() ? "arrow.uturn.backward.circle" : "checkmark.circle")
                        }
                        .tint(.accentColor)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Supplements")
            .searchable(text: $searchQuery)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSupplement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplement) {
                AddSupplementView()
            }
            .overlay {
                if supplements.isEmpty {
                    ContentUnavailableView("No Supplements", systemImage: "pills", description: Text("Tap the + button to add your first supplement."))
                } else if filteredSupplements.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView.search(text: searchQuery)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickAddSupplement)) { _ in
            showingAddSupplement = true
        }
    }
    
    private func toggleTakenToday(for supplement: Supplement) {
        if let intake = supplement.intakes.first(where: { Calendar.current.isDateInToday($0.date) }) {
            modelContext.delete(intake)
        } else {
            let intake = SupplementIntake(supplementID: supplement.id, date: Date())
            modelContext.insert(intake)
            supplement.intakes.append(intake)
        }
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let supp = supplements[index]
            NotificationService().cancelSupplementReminder(for: supp)
            modelContext.delete(supp)
        }
    }
}

private struct EditSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String
    @State private var dosage: String
    @State private var notes: String
    @State private var scheduleType: SupplementScheduleType
    @State private var selectedWeekdays: Set<Int>
    @State private var weeklyWeekday: Int
    @State private var time: Date
    let supplement: Supplement
    
    init(supplement: Supplement) {
        self.supplement = supplement
        _name = State(initialValue: supplement.name)
        _dosage = State(initialValue: supplement.dosage ?? "")
        _notes = State(initialValue: supplement.notes ?? "")
        _scheduleType = State(initialValue: supplement.scheduleType)
        _weeklyWeekday = State(initialValue: supplement.weeklyWeekday ?? 2)
        let days = Set(supplement.specificDaysList())
        _selectedWeekdays = State(initialValue: days)
        let comps = supplement.timeComponents() ?? DateComponents(hour: 8, minute: 0)
        _time = State(initialValue: Calendar.current.date(from: comps) ?? Date())
    }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                TextField("Dosage (optional)", text: $dosage)
                TextField("Notes (optional)", text: $notes)
            }
            Section("Schedule") {
                Picker("Frequency", selection: $scheduleType) {
                    Text("Daily").tag(SupplementScheduleType.daily)
                    Text("Weekly").tag(SupplementScheduleType.weekly)
                    Text("Specific Days").tag(SupplementScheduleType.specificDays)
                }
                .pickerStyle(.segmented)
                switch scheduleType {
                case .daily:
                    EmptyView()
                case .weekly:
                    Picker("Weekday", selection: $weeklyWeekday) {
                        ForEach(1...7, id: \.self) { idx in
                            Text(Calendar.current.weekdaySymbols[idx - 1]).tag(idx)
                        }
                    }
                case .specificDays:
                    WeekdayPicker(selected: $selectedWeekdays)
                }
                DatePicker("Time of Day (optional)", selection: $time, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Edit Supplement")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { save() }
            }
        }
    }
    
    private func save() {
        supplement.name = name
        supplement.dosage = dosage.isEmpty ? nil : dosage
        supplement.notes = notes.isEmpty ? nil : notes
        supplement.scheduleTypeRaw = scheduleType.rawValue
        switch scheduleType {
        case .daily:
            supplement.weeklyWeekday = nil
            supplement.specificDaysMask = nil
        case .weekly:
            supplement.weeklyWeekday = weeklyWeekday
            supplement.specificDaysMask = nil
        case .specificDays:
            let mask = selectedWeekdays.sorted().reduce(0) { $0 | (1 << ($1 - 1)) }
            supplement.specificDaysMask = mask
            supplement.weeklyWeekday = nil
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        supplement.timeHour = comps.hour
        supplement.timeMinute = comps.minute
        if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
            WidgetSnapshotService(modelContainer: container).writeSnapshot()
        }
        dismiss()
    }
}

// Local weekday multi-select to avoid cross-file dependency
private struct WeekdayPicker: View {
    @Binding var selected: Set<Int>
    private let symbols = Calendar.current.weekdaySymbols // Sunday..Saturday
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

private struct SupplementRowView: View {
    let supplement: Supplement
    
    var body: some View {
        HStack {
            Image(systemName: supplement.wasTakenToday() ? "checkmark.circle.fill" : "circle")
                .foregroundColor(supplement.wasTakenToday() ? .accentColor : .secondary)
            VStack(alignment: .leading) {
                Text(supplement.name)
                if let dosage = supplement.dosage, !dosage.isEmpty {
                    Text(dosage).font(.caption).foregroundColor(.secondary)
                }
                Text(scheduleSummary(supplement))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let t = supplement.timeComponents(), let h = t.hour, let m = t.minute {
                Text(String(format: "%02d:%02d", h, m))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func scheduleSummary(_ s: Supplement) -> String {
        switch s.scheduleType {
        case .daily: return "Daily"
        case .weekly:
            let wd = s.weeklyWeekday ?? 2
            return weekdaySymbol(wd)
        case .specificDays:
            let days = s.specificDaysList().sorted()
            return days.map { weekdaySymbol($0) }.joined(separator: ", ")
        }
    }
    
    private func weekdaySymbol(_ weekday: Int) -> String {
        let syms = Calendar.current.shortWeekdaySymbols // Sun..Sat
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return syms[weekday - 1]
    }
}



