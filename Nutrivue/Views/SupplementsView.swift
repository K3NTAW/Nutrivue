import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var supplements: [Supplement]
    @State private var showingAddSupplement = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(supplements) { supp in
                    SupplementRowView(supplement: supp)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Supplements")
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickAddSupplement)) { _ in
            showingAddSupplement = true
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


