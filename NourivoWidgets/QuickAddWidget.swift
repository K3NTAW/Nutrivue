import WidgetKit
import SwiftUI

struct QuickAddEntry: TimelineEntry { let date: Date }

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> ()) {
        let entry = QuickAddEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = QuickAddEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickAddSmallView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle.fill").font(.system(size: 24, weight: .semibold)).foregroundColor(.accentColor)
            Text("Add Food").font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "nutrivue://add/food"))
    }
}

struct QuickAddMediumView: View {
    var body: some View {
        let items: [(String, String, String)] = [
            ("plus.circle.fill", "Food", "nutrivue://add/food"),
            ("book", "Recipe", "nutrivue://add/recipe"),
            ("barcode.viewfinder", "Scan", "nutrivue://scan"),
            ("pills", "Supplement", "nutrivue://add/supplement")
        ]
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ForEach(items, id: \.1) { icon, title, url in
                Link(destination: URL(string: url)!) {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.accentColor)
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemFill)))
                }
            }
        }
        .padding(12)
    }
}

struct QuickAddWidget: Widget {
    @Environment(\.widgetFamily) var family

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickAddWidget", provider: QuickAddProvider()) { entry in
            QuickAddMediumView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Add")
        .description("Add food, recipes, scan, or supplements quickly.")
        .supportedFamilies([.systemMedium])
    }
}


