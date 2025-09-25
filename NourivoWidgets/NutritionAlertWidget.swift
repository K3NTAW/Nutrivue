import WidgetKit
import SwiftUI

struct NutriAlert: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let color: Color
}

struct AlertsEntry: TimelineEntry {
    let date: Date
    let alerts: [NutriAlert]

    init(date: Date, snapshot: SharedSnapshot?) {
        self.date = date
        var a: [NutriAlert] = []
        if let s = snapshot {
            // Logic to generate real alerts based on snapshot can go here
            if (s.calories > s.calorieGoal * 0.9) { a.append(NutriAlert(title: "Calories near goal", symbol: "flame.fill", color: .yellow)) }
            if (s.macros.p < s.macros.pGoal * 0.5) { a.append(NutriAlert(title: "Protein low", symbol: "bolt", color: .red)) }
        } else {
            // Provide mock data for previews
            a.append(NutriAlert(title: "Calories near goal", symbol: "flame.fill", color: .yellow))
            a.append(NutriAlert(title: "Protein low", symbol: "bolt", color: .red))
        }
        self.alerts = a
    }
}

struct AlertsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AlertsEntry { mock() }
    func getSnapshot(in context: Context, completion: @escaping (AlertsEntry) -> ()) { completion(mock()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AlertsEntry>) -> ()) {
        let entry: AlertsEntry
        if let s = SharedSnapshotReader.read() {
            var alerts: [NutriAlert] = []
            if s.calories > s.calorieGoal { alerts.append(NutriAlert(title: "Calories over goal", symbol: "flame.fill", color: .red)) }
            if s.macros.f > s.macros.fGoal { alerts.append(NutriAlert(title: "Fat over goal", symbol: "drop", color: .red)) }
            if s.macros.c > s.macros.cGoal { alerts.append(NutriAlert(title: "Carbs over goal", symbol: "leaf", color: .red)) }
            if s.macros.p > s.macros.pGoal { alerts.append(NutriAlert(title: "Protein over goal", symbol: "bolt", color: .red)) }
            entry = AlertsEntry(date: s.date, snapshot: s)
        } else { entry = mock() }
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    private func mock() -> AlertsEntry {
        AlertsEntry(date: Date(), snapshot: nil)
    }
}

struct NutritionAlertSmallView: View {
    let entry: AlertsEntry
    var body: some View {
        let first = entry.alerts.first
        VStack(spacing: 6) {
            Image(systemName: first?.symbol ?? "exclamationmark.triangle")
                .foregroundColor(first?.color ?? .yellow)
                .font(.system(size: 22, weight: .semibold))
            Text(first?.title ?? "All good")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
    }
}

struct NutritionAlertMediumView: View {
    let entry: AlertsEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.alerts.prefix(3)) { alert in
                HStack(spacing: 8) {
                    Image(systemName: alert.symbol).foregroundColor(alert.color)
                    Text(alert.title).font(.caption)
                    Spacer()
                }
            }
            if entry.alerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal").foregroundColor(.green)
                    Text("No alerts").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
    }
}

struct NutritionAlertWidget: Widget {
    @Environment(\.widgetFamily) var family

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NutritionAlertWidget", provider: AlertsProvider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    switch family {
                    case .systemSmall:
                        NutritionAlertSmallView(entry: entry)
                    case .systemMedium:
                        NutritionAlertMediumView(entry: entry)
                    default:
                        NutritionAlertSmallView(entry: entry)
                    }
                } else {
                    switch family {
                    case .systemSmall:
                        NutritionAlertSmallView(entry: entry)
                    case .systemMedium:
                        NutritionAlertMediumView(entry: entry)
                    default:
                        NutritionAlertSmallView(entry: entry)
                    }
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nutrition Alerts")
        .description("Shows key nutrition alerts at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


