import WidgetKit
import SwiftUI

struct MacroEntry: TimelineEntry {
    let date: Date
    let protein: Double
    let proteinGoal: Double
    let carbs: Double
    let carbsGoal: Double
    let fat: Double
    let fatGoal: Double

    init(date: Date, snapshot: SharedSnapshot?) {
        self.date = date
        if let s = snapshot {
            self.protein = s.macros.p
            self.proteinGoal = s.macros.pGoal
            self.carbs = s.macros.c
            self.carbsGoal = s.macros.cGoal
            self.fat = s.macros.f
            self.fatGoal = s.macros.fGoal
        } else {
            // Provide mock data for previews
            self.protein = 85
            self.proteinGoal = 150
            self.carbs = 160
            self.carbsGoal = 220
            self.fat = 55
            self.fatGoal = 70
        }
    }
}

struct MacroProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry { mock() }
    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> ()) { completion(mock()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> ()) {
        let entry: MacroEntry
        if let s = SharedSnapshotReader.read() {
            entry = MacroEntry(date: s.date, snapshot: s)
        } else { entry = mock() }
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    private func mock() -> MacroEntry { MacroEntry(date: Date(), snapshot: nil) }
}

struct MacroSummarySmallView: View {
    let entry: MacroEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MacroBar(name: "Protein", current: entry.protein, goal: entry.proteinGoal, color: .purple)
            MacroBar(name: "Carbs", current: entry.carbs, goal: entry.carbsGoal, color: .green)
            MacroBar(name: "Fat", current: entry.fat, goal: entry.fatGoal, color: .orange)
        }
        .padding(10)
    }
}

struct MacroSummaryMediumView: View {
    let entry: MacroEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MacroBar(name: "Protein", current: entry.protein, goal: entry.proteinGoal, color: .purple)
            OverText(current: entry.protein, goal: entry.proteinGoal)
            MacroBar(name: "Carbs", current: entry.carbs, goal: entry.carbsGoal, color: .green)
            OverText(current: entry.carbs, goal: entry.carbsGoal)
            MacroBar(name: "Fat", current: entry.fat, goal: entry.fatGoal, color: .orange)
            OverText(current: entry.fat, goal: entry.fatGoal)
        }
        .padding(12)
    }
}

struct OverText: View {
    let current: Double
    let goal: Double
    var body: some View {
        let over = current - goal
        if over > 0 {
            Text(String(format: "Over by %.0f g", over)).font(.caption2).foregroundColor(.red)
        }
    }
}

struct MacroSummaryWidget: Widget {
    @Environment(\.widgetFamily) var family

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MacroSummaryWidget", provider: MacroProvider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    switch family {
                    case .systemSmall:
                        MacroSummarySmallView(entry: entry)
                    case .systemMedium:
                        MacroSummaryMediumView(entry: entry)
                    default:
                        MacroSummarySmallView(entry: entry)
                    }
                } else {
                    switch family {
                    case .systemSmall:
                        MacroSummarySmallView(entry: entry)
                    case .systemMedium:
                        MacroSummaryMediumView(entry: entry)
                    default:
                        MacroSummarySmallView(entry: entry)
                    }
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Macro Summary")
        .description("Protein, carbs, and fat at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


