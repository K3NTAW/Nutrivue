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
                    Button(action: {
                        toggleTakenToday(for: supp)
                    }) {
                        SupplementRowView(supplement: supp)
                    }
                    .buttonStyle(.plain)
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


