import WidgetKit
import SwiftUI

struct SupplementDue: Identifiable {
    let id = UUID()
    let name: String
    let time: Date
    let isTaken: Bool
}

struct SupplementsEntry: TimelineEntry {
    let date: Date
    let dueToday: [SupplementDue]

    init(date: Date, snapshot: SharedSnapshot?) {
        self.date = date
        if let s = snapshot {
            self.dueToday = s.supplements.list.map {
                SupplementDue(name: $0.name, time: $0.time, isTaken: $0.taken)
            }
        } else {
            // Provide mock data for previews
            self.dueToday = [
                SupplementDue(name: "Vitamin D", time: Date().addingTimeInterval(3600), isTaken: false),
                SupplementDue(name: "Omega-3", time: Date().addingTimeInterval(3600), isTaken: true),
                SupplementDue(name: "Magnesium", time: Date().addingTimeInterval(10800), isTaken: false),
            ]
        }
    }
}

struct SupplementsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SupplementsEntry { mock() }
    func getSnapshot(in context: Context, completion: @escaping (SupplementsEntry) -> ()) { completion(mock()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SupplementsEntry>) -> ()) {
        let snapshot = SharedSnapshotReader.read()
        let entry = SupplementsEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    private func mock() -> SupplementsEntry {
        let cal = Calendar.current
        let base = Date()
        return SupplementsEntry(date: base, snapshot: nil) // Mock with nil snapshot
    }
}

struct SupplementsSmallView: View {
    let entry: SupplementsEntry
    var nextDue: SupplementDue? {
        entry.dueToday.filter { !$0.isTaken }.sorted { $0.time < $1.time }.first
    }
    var body: some View {
        if let item = nextDue {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "pills").foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(item.time, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .widgetURL(URL(string: "nutrivue://supplements/next"))
        } else {
            VStack(spacing: 6) {
                Image(systemName: "pills").foregroundColor(.secondary)
                Text("No supplements due")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
        }
    }
}

struct SupplementsMediumView: View {
    let entry: SupplementsEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.dueToday.prefix(4)) { item in
                HStack {
                    Image(systemName: item.isTaken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isTaken ? .green : .secondary)
                    Text(item.name).lineLimit(1)
                    Spacer()
                    Text(item.time, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            if entry.dueToday.isEmpty {
                HStack {
                    Image(systemName: "pills").foregroundColor(.secondary)
                    Text("No supplements due today").foregroundColor(.secondary).font(.caption)
                }
            }
        }
        .padding(12)
        .widgetURL(URL(string: "nutrivue://supplements/today"))
    }
}

struct SupplementsReminderWidget: Widget {
    @Environment(\.widgetFamily) var family

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SupplementsReminderWidget", provider: SupplementsProvider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    switch family {
                    case .systemSmall:
                        SupplementsSmallView(entry: entry)
                    case .systemMedium:
                        SupplementsMediumView(entry: entry)
                    default:
                        SupplementsSmallView(entry: entry)
                    }
                } else {
                    switch family {
                    case .systemSmall:
                        SupplementsSmallView(entry: entry)
                    case .systemMedium:
                        SupplementsMediumView(entry: entry)
                    default:
                        SupplementsSmallView(entry: entry)
                    }
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Supplements")
        .description("Next due and today’s supplements at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


