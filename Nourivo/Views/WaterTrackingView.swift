import SwiftUI
import SwiftData

struct WaterTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterIntakes: [WaterIntake]
    @Query private var users: [User]
    
    private var unitSystem: UnitSystem { users.first?.unitSystem ?? .metric }
    private var totalToday: Double { WaterIntake.totalToday(intakes: waterIntakes) }
    private var goalAmount: Double { 2000.0 } // 2 liters default goal
    
    @State private var showingAddWater = false
    @State private var selectedAmount: Double = 250
    
    private let waterAmounts = [100, 150, 200, 250, 300, 350, 400, 500]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.adaptiveBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Water Tracking")
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.3)
                                    
                                    Text("Stay hydrated throughout the day")
                                        .font(.system(size: 17, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .opacity(0.85)
                                        .kerning(0.1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showingAddWater = true
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
                        
                        // Water Progress Card
                        VStack(spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Today's Hydration")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            // Water Progress Ring
                            VStack(spacing: 16) {
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(DesignSystem.Colors.adaptiveSurface().opacity(0.3), lineWidth: 12)
                                        .frame(width: 160, height: 160)
                                    
                                    // Progress circle
                                    Circle()
                                        .trim(from: 0, to: min(totalToday / goalAmount, 1.0))
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.blue, Color.cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                        )
                                        .frame(width: 160, height: 160)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 1.0), value: totalToday)
                                    
                                    // Center content
                                    VStack(spacing: 4) {
                                        Text("\(String(format: "%.0f", totalToday))")
                                            .font(.system(size: 32, weight: .bold, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                            .kerning(-1.0)
                                        
                                        Text(unitSystem == .metric ? "ml" : "fl oz")
                                            .font(.system(size: 14, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .kerning(0.2)
                                        
                                        Text("of \(String(format: "%.0f", goalAmount)) \(unitSystem == .metric ? "ml" : "fl oz")")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                            .opacity(0.8)
                                            .kerning(0.1)
                                    }
                                }
                                
                                // Progress percentage
                                Text("\(String(format: "%.0f", (totalToday / goalAmount) * 100))%")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .kerning(0.2)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Quick Add Buttons
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Quick Add")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                                ForEach(waterAmounts, id: \.self) { amount in
                                    Button(action: {
                                        addWater(amount: Double(amount))
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("\(amount)")
                                                .font(.system(size: 16, weight: .bold, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                                .kerning(-0.3)
                                            
                                            Text(unitSystem == .metric ? "ml" : "fl oz")
                                                .font(.system(size: 10, weight: .medium, design: .default))
                                                .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                                .kerning(0.2)
                                        }
                                        .frame(width: 60, height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(DesignSystem.Colors.adaptiveCardBackground())
                                                .shadow(
                                                    color: .black.opacity(0.08),
                                                    radius: 6,
                                                    x: 0,
                                                    y: 3
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Today's Intakes
                        if !waterIntakes.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                    
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    Text("Today's Intakes")
                                        .font(.system(size: 20, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(0.3)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                List {
                                    ForEach(todayIntakes.prefix(5)) { intake in
                                        WaterIntakeRow(intake: intake, unitSystem: unitSystem)
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    deleteWaterIntake(intake)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .frame(height: CGFloat(min(todayIntakes.count, 5)) * 70)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddWater) {
                AddWaterView(selectedAmount: $selectedAmount)
            }
        }
    }
    
    private var todayIntakes: [WaterIntake] {
        let calendar = Calendar.current
        return waterIntakes
            .filter { calendar.isDate($0.date, inSameDayAs: Date()) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private func addWater(amount: Double) {
        let intake = WaterIntake(amount: amount)
        modelContext.insert(intake)
    }
    
    private func deleteWaterIntake(_ intake: WaterIntake) {
        modelContext.delete(intake)
    }
}

private struct WaterIntakeRow: View {
    let intake: WaterIntake
    let unitSystem: UnitSystem
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var relativeTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(intake.timestamp)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            return relativeTimeFormatter.string(from: intake.timestamp)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(String(format: "%.0f", intake.amount)) \(unitSystem == .metric ? "ml" : "fl oz")")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                        .kerning(0.1)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                        .kerning(0.1)
                }
                
                Text(relativeTimeFormatter.string(from: intake.timestamp))
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                    .kerning(0.1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.adaptiveCardBackground())
                .shadow(
                    color: .black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

#Preview {
    WaterTrackingView()
}
