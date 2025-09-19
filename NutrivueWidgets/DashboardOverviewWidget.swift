import WidgetKit
import SwiftUI

struct OverviewEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let goal: Double
    let supplementsDue: Int
    let supplementsTaken: Int
    let last7: [Double]
}

struct OverviewProvider: TimelineProvider {
    func placeholder(in context: Context) -> OverviewEntry { mock() }
    func getSnapshot(in context: Context, completion: @escaping (OverviewEntry) -> ()) { completion(mock()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OverviewEntry>) -> ()) {
        let entry: OverviewEntry
        if let s = SharedSnapshotReader.read() {
            entry = OverviewEntry(date: s.date, calories: s.calories, goal: s.calorieGoal, supplementsDue: s.supplements.due, supplementsTaken: s.supplements.taken, last7: s.weekly.last7)
        } else { entry = mock() }
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }
    private func mock() -> OverviewEntry {
        OverviewEntry(date: Date(), calories: 1450, goal: 2000, supplementsDue: 3, supplementsTaken: 1, last7: [1800, 1900, 2100, 1700, 2200, 1600, 2000])
    }
}

struct DashboardOverviewLargeView: View {
    let entry: OverviewEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Calories ring
            HStack(alignment: .center, spacing: 12) {
                ProgressRingWidget(progress: entry.calories / max(entry.goal, 1), overflow: max(0, entry.calories / max(entry.goal, 1) - 1))
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(entry.calories)) kcal").font(.headline)
                    Text("Goal \(Int(entry.goal))").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            // Supplements status
            HStack(spacing: 8) {
                Image(systemName: "pills")
                Text("Supplements: \(entry.supplementsTaken)/\(entry.supplementsDue)")
                Spacer()
            }
            .font(.subheadline)
            // Weekly bars
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly Calories").font(.caption).foregroundColor(.secondary)
                GeometryReader { geo in
                    let maxVal = max(entry.goal, entry.last7.max() ?? entry.goal)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(entry.last7.indices, id: \.self) { idx in
                            let value = entry.last7[idx]
                            let h = max(6, geo.size.height * CGFloat(value / maxVal))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(value > entry.goal ? Color.red : Color.accentColor)
                                .frame(width: (geo.size.width - 6 * 6) / 7, height: h)
                        }
                    }
                }
                .frame(height: 48)
            }
        }
        .padding(12)
    }
}

struct DashboardOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DashboardOverviewWidget", provider: OverviewProvider()) { entry in
            DashboardOverviewLargeView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Dashboard Overview")
        .description("Calories, supplements, and weekly trend at a glance.")
        .supportedFamilies([.systemLarge])
    }
}


