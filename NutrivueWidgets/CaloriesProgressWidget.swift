import WidgetKit
import SwiftUI

struct CaloriesEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let goal: Double
    let protein: Double
    let proteinGoal: Double
    let carbs: Double
    let carbsGoal: Double
    let fat: Double
    let fatGoal: Double
}

struct CaloriesProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaloriesEntry {
        mock()
    }
    func getSnapshot(in context: Context, completion: @escaping (CaloriesEntry) -> ()) {
        if let s = SharedSnapshotReader.read() {
            completion(CaloriesEntry(date: s.date, calories: s.calories, goal: s.calorieGoal, protein: s.macros.p, proteinGoal: s.macros.pGoal, carbs: s.macros.c, carbsGoal: s.macros.cGoal, fat: s.macros.f, fatGoal: s.macros.fGoal))
        } else {
            completion(mock())
        }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CaloriesEntry>) -> ()) {
        let entry: CaloriesEntry
        if let s = SharedSnapshotReader.read() {
            entry = CaloriesEntry(date: s.date, calories: s.calories, goal: s.calorieGoal, protein: s.macros.p, proteinGoal: s.macros.pGoal, carbs: s.macros.c, carbsGoal: s.macros.cGoal, fat: s.macros.f, fatGoal: s.macros.fGoal)
        } else {
            entry = mock()
        }
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func mock() -> CaloriesEntry {
        CaloriesEntry(date: Date(), calories: 1450, goal: 2000, protein: 85, proteinGoal: 150, carbs: 160, carbsGoal: 220, fat: 55, fatGoal: 70)
    }
}

struct CaloriesProgressSmallView: View {
    let entry: CaloriesEntry
    var body: some View {
        ZStack {
            ProgressRingWidget(progress: entry.calories / max(entry.goal, 1), overflow: max(0, entry.calories / max(entry.goal, 1) - 1))
            VStack(spacing: 2) {
                Text("\(Int(entry.calories))").font(.system(size: 20, weight: .bold))
                Text("kcal").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(8)
    }
}

struct CaloriesProgressMediumView: View {
    let entry: CaloriesEntry
    var body: some View {
        HStack {
            ProgressRingWidget(progress: entry.calories / max(entry.goal, 1), overflow: max(0, entry.calories / max(entry.goal, 1) - 1))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 6) {
                MacroBar(name: "Protein", current: entry.protein, goal: entry.proteinGoal, color: .purple)
                MacroBar(name: "Carbs", current: entry.carbs, goal: entry.carbsGoal, color: .green)
                MacroBar(name: "Fat", current: entry.fat, goal: entry.fatGoal, color: .orange)
            }
        }
        .padding(12)
    }
}

struct ProgressRingWidget: View {
    let progress: Double
    let overflow: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.accentColor.opacity(0.25), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if overflow > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(min(overflow, 1)))
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

struct MacroBar: View {
    let name: String
    let current: Double
    let goal: Double
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name).font(.caption2)
                Spacer()
                Text("\(Int(current)) / \(Int(goal))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                let p = current / max(goal, 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule().fill(p > 1 ? Color.red : color)
                        .frame(width: geo.size.width * CGFloat(min(p, 1)))
                }
            }
            .frame(height: 6)
        }
    }
}

struct CaloriesProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CaloriesProgressWidget", provider: CaloriesProvider()) { entry in
            CaloriesProgressSmallView(entry: entry)
        }
        .configurationDisplayName("Calories Progress")
        .description("Calories ring and macros at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


