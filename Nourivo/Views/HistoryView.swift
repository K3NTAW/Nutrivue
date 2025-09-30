import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query(sort: \Meal.date) private var meals: [Meal]
    @Query private var supplements: [Supplement]
    @Query(sort: \SupplementIntake.date) private var intakes: [SupplementIntake]
    
    @State private var daysRange: Int = 7
    
    private var goalCalories: Double {
        users.first?.goals?.calories ?? 2000
    }
    private var lowerBand: Double { goalCalories * 0.95 }
    private var upperBand: Double { goalCalories * 1.05 }
    private var logsForRange: [DailyLog] { buildDailyLogs(lastDays: daysRange) }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        // Time Range Picker
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Time Range")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            Picker("Range", selection: $daysRange) {
                                Text("7 days").tag(7)
                                Text("14 days").tag(14)
                                Text("30 days").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Calorie Chart
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Calorie Intake")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            CalorieChartView(logs: logsForRange, lowerBand: lowerBand, upperBand: upperBand)
                                .frame(height: 220)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .dataCardStyle()
                                .accessibilityLabel("Calories chart last \(daysRange) days")
                        }
                        
                        // Supplement Adherence
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .font(.title3)
                                
                                Text("Supplement Adherence")
                                    .font(DesignSystem.Typography.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            AdherenceRow(logs: logsForRange)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .accessibilityLabel("Supplement adherence last \(daysRange) days")
                        }
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                    .padding(.top, DesignSystem.Spacing.sm)
                }
            }
            .navigationTitle("History")
        }
    }
    
    private func buildDailyLogs(lastDays: Int) -> [DailyLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<lastDays).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
        let mealsByDay = Dictionary(grouping: meals) { calendar.startOfDay(for: $0.date) }
        let intakesByDay = Dictionary(grouping: intakes) { calendar.startOfDay(for: $0.date) }
        return days.map { day in
            let dayMeals = mealsByDay[day] ?? []
            let kcal = dayMeals.flatMap { $0.items }.reduce(0) { $0 + $1.calories }
            let scheduled = supplements.filter { $0.isScheduledForDate(day) }.count
            let taken = (intakesByDay[day] ?? []).count
            return DailyLog(date: day, calories: kcal, scheduledSupplements: scheduled, takenSupplements: taken)
        }
    }
}

private struct DailyLog: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let scheduledSupplements: Int
    let takenSupplements: Int
}

private struct CalorieChartView: View {
    let logs: [DailyLog]
    let lowerBand: Double
    let upperBand: Double
    
    var body: some View {
        GeometryReader { geo in
            let maxY = max(upperBand, logs.map { $0.calories }.max() ?? 0, 1)
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                // Range band
                let bandTopY = y(for: upperBand, maxY: maxY, height: height)
                let bandBottomY = y(for: lowerBand, maxY: maxY, height: height)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: width, height: max(1, bandBottomY - bandTopY))
                    .position(x: width / 2, y: (bandTopY + bandBottomY) / 2)
                
                // Bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, log in
                        let barWidth = max(8, (width / CGFloat(max(1, logs.count))) * 0.6)
                        let barHeight = max(2, height - y(for: log.calories, maxY: maxY, height: height))
                        let color: Color = {
                            if log.calories > upperBand { return .red }
                            if log.calories < lowerBand { return .yellow }
                            return .green
                        }()
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: barWidth, height: barHeight)
                                .accessibilityLabel("\(DateFormatter.shortWeekday(log.date)) calories: \(Int(log.calories))")
                            Text(shortLabel(for: log.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: barWidth)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(width: width, height: height, alignment: .bottom)
            }
        }
    }
    
    private func y(for value: Double, maxY: Double, height: CGFloat) -> CGFloat {
        let ratio = value / maxY
        return height * CGFloat(1 - min(max(ratio, 0), 1))
    }
    
    private func shortLabel(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df.string(from: date)
    }
}

private struct AdherenceRow: View {
    let logs: [DailyLog]
    var body: some View {
        HStack(spacing: 12) {
            ForEach(logs) { log in
                VStack(spacing: 4) {
                    Image(systemName: symbol(for: log))
                        .foregroundColor(color(for: log))
                    Text(dayNum(for: log.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("\(DateFormatter.shortWeekday(log.date)) adherence: \(statusDescription(for: log))")
            }
        }
    }
    
    private func symbol(for log: DailyLog) -> String {
        if log.scheduledSupplements == 0 { return "minus.circle" }
        if log.takenSupplements >= log.scheduledSupplements { return "checkmark.circle.fill" }
        return "xmark.circle.fill"
    }
    
    private func color(for log: DailyLog) -> Color {
        if log.scheduledSupplements == 0 { return Color(.tertiaryLabel) }
        if log.takenSupplements >= log.scheduledSupplements { return .green }
        return .red
    }
    
    private func dayNum(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df.string(from: date)
    }
    
    private func statusDescription(for log: DailyLog) -> String {
        if log.scheduledSupplements == 0 { return "no supplements" }
        return log.takenSupplements >= log.scheduledSupplements ? "taken" : "missed"
    }
}

private extension DateFormatter {
    static func shortWeekday(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df.string(from: date)
    }
}
