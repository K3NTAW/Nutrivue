import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @State private var showingAddSupplement = false
    @State private var selectedSupplement: Supplement?
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
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Supplements")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.3)
                                
                                Text("Track your supplement routine")
                                    .font(.system(size: 17, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .opacity(0.85)
                                    .kerning(0.1)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddSupplement = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    
                    if supplements.isEmpty {
                        // Empty State
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "pills")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            
                            VStack(spacing: 12) {
                                Text("No Supplements Yet")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.3)
                                
                                Text("Start building your supplement routine by adding your first supplement")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .multilineTextAlignment(.center)
                                    .kerning(0.1)
                                    .opacity(0.8)
                            }
                            
                            Button(action: {
                                showingAddSupplement = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Add Supplement")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: DesignSystem.Colors.accent.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 48)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredSupplements.isEmpty && !searchQuery.isEmpty {
                        // No Search Results
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.adaptiveTertiaryText().opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                            }
                            
                            VStack(spacing: 12) {
                                Text("No Results Found")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(-0.3)
                                
                                Text("No supplements found for '\(searchQuery)'")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .multilineTextAlignment(.center)
                                    .kerning(0.1)
                                    .opacity(0.8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 48)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Supplements List
                        List {
                            ForEach(filteredSupplements) { supplement in
                                SupplementCardView(
                                    supplement: supplement,
                                    onToggle: { toggleTakenToday(for: supplement) },
                                    onEdit: { 
                                        selectedSupplement = supplement
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        toggleTakenToday(for: supplement)
                                    } label: {
                                        Label(supplement.wasTakenToday() ? "Unmark" : "Mark Taken", systemImage: supplement.wasTakenToday() ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                    }
                                    .tint(DesignSystem.Colors.accent)
                                    
                                    Button(role: .destructive) {
                                        deleteSupplement(supplement)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        toggleTakenToday(for: supplement)
                                    } label: {
                                        Label(supplement.wasTakenToday() ? "Unmark" : "Mark Taken", systemImage: supplement.wasTakenToday() ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteSupplement(supplement)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 16, trailing: 24))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchQuery)
            .sheet(isPresented: $showingAddSupplement) {
                AddSupplementView()
            }
            .sheet(item: $selectedSupplement) { supplement in
                EditSupplementView(supplement: supplement)
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
    
    private func deleteSupplement(_ supplement: Supplement) {
        NotificationService().cancelSupplementReminder(for: supplement)
        modelContext.delete(supplement)
    }
}

// MARK: - Helper Views
private struct SupplementCardView: View {
    let supplement: Supplement
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            ZStack {
                Circle()
                    .fill(supplement.wasTakenToday() ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: supplement.wasTakenToday() ? "checkmark" : "pills")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(supplement.wasTakenToday() ? DesignSystem.Colors.success : DesignSystem.Colors.accent)
            }
            
            // Supplement Info
            VStack(alignment: .leading, spacing: 6) {
                Text(supplement.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .kerning(0.2)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let dosage = supplement.dosage, !dosage.isEmpty {
                        Text(dosage)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.6))
                            )
                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            .kerning(0.1)
                    }
                    
                    if let timeComponents = supplement.timeComponents(),
                       let hour = timeComponents.hour,
                       let minute = timeComponents.minute {
                        Text(String(format: "%02d:%02d", hour, minute))
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.adaptiveSurface().opacity(0.6))
                            )
                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            .kerning(0.1)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(supplement.wasTakenToday() ? DesignSystem.Colors.success : DesignSystem.Colors.adaptiveSurface())
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: supplement.wasTakenToday() ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(supplement.wasTakenToday() ? .white : DesignSystem.Colors.adaptiveSecondaryText())
                }
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
        .onTapGesture {
            onEdit()
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




