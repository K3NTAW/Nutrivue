//
//  ContentView.swift
//  Nourivo
//
//  Created by Kenta Waibel on 17.09.2025.
//

import SwiftUI
import SwiftData
import WidgetKit

extension Notification.Name {
    static let navigationSettingsChanged = Notification.Name("navigationSettingsChanged")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]
    @Query(sort: \Meal.date) private var meals: [Meal]
    @State private var showOnboarding = false
    @State private var selectedTab: Int = 0
    @State private var showingNavigationSettings = false
    @State private var refreshID = UUID()
    
    enum NavigationTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case water = "Water"
        case recipes = "Recipes"
        case log = "Log"
        case supplements = "Supplements"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .water: return "drop"
            case .recipes: return "book"
            case .log: return "plus.circle"
            case .supplements: return "pills"
            case .settings: return "gear"
            }
        }
        
        var color: Color {
            switch self {
            case .dashboard: return .blue
            case .water: return .cyan
            case .recipes: return .orange
            case .log: return .green
            case .supplements: return .purple
            case .settings: return .gray
            }
        }
    }
    
    private var selectedTabs: [NavigationTab] {
        let savedTabs = UserDefaults.standard.stringArray(forKey: "selectedNavigationTabs") ?? []
        let tabSet = Set(savedTabs.compactMap { NavigationTab(rawValue: $0) })
        
        // Ensure log and settings are always included and we have at least 3 tabs
        if tabSet.isEmpty {
            return [.dashboard, .log, .settings]
        }
        
        // Always include log and settings tabs
        var tabs = Array(tabSet)
        if !tabs.contains(.log) {
            tabs.append(.log)
        }
        if !tabs.contains(.settings) {
            tabs.append(.settings)
        }
        
        // Sort to put log in the middle and settings at the end
        tabs.sort { tab1, tab2 in
            if tab1 == .log { return false }
            if tab2 == .log { return true }
            if tab1 == .settings { return false }
            if tab2 == .settings { return true }
            return tab1.rawValue < tab2.rawValue
        }
        
        // Ensure log is in the middle position
        if let logIndex = tabs.firstIndex(of: .log) {
            let middleIndex = tabs.count / 2
            if logIndex != middleIndex {
                tabs.remove(at: logIndex)
                tabs.insert(.log, at: middleIndex)
            }
        }
        
        // Ensure settings is at the end
        if let settingsIndex = tabs.firstIndex(of: .settings) {
            tabs.remove(at: settingsIndex)
            tabs.append(.settings)
        }
        
        return tabs
    }
    
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var totalFoodItemsToday: Int {
        todaysMeals.flatMap { $0.items }.count
    }
    
    var body: some View {
        if users.isEmpty {
            // Trigger onboarding as a full-screen cover so nothing shows underneath
            Color(.systemBackground)
                .ignoresSafeArea()
                .onAppear { showOnboarding = true }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(showOnboarding: $showOnboarding)
                        .interactiveDismissDisabled(true)
                }
        } else {
            TabView(selection: $selectedTab) {
                ForEach(Array(selectedTabs.enumerated()), id: \.element) { index, tab in
                    viewForTab(tab)
                        .tabItem {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                        .tag(index)
                }
            }
            .id(refreshID)
            .onAppear(perform: createTodaysMealsIfNeeded)
            .onChange(of: totalFoodItemsToday) {
                // When the number of food items changes, write a new snapshot
                // and tell the widgets to refresh.
                let snapshotService = SnapshotService(modelContext: modelContext)
                snapshotService.writeSnapshot()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigationSettingsChanged)) { _ in
                refreshID = UUID()
            }
        }
    }
    
    private func createTodaysMealsIfNeeded() {
        if todaysMeals.isEmpty {
            let mealNames = ["Breakfast", "Lunch", "Dinner", "Snacks"]
            for name in mealNames {
                let newMeal = Meal(name: name, items: [], date: Date())
                modelContext.insert(newMeal)
            }
        }
    }

    @ViewBuilder
    private func viewForTab(_ tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .water:
            WaterTrackingView()
        case .recipes:
            RecipesView()
        case .log:
            LogView()
        case .supplements:
            SupplementsView()
        case .settings:
            SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // nutrivue://add/food, nutrivue://add/recipe, nutrivue://scan, nutrivue://add/supplement
        guard url.scheme == "nutrivue" else { return }
        let path = url.host ?? ""
        
        // Find the appropriate tab index
        switch path {
        case "add":
            if url.path == "/food" {
                if let logIndex = selectedTabs.firstIndex(of: .log) {
                    selectedTab = logIndex
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddFood, object: nil)
                }
            } else if url.path == "/recipe" {
                if let logIndex = selectedTabs.firstIndex(of: .log) {
                    selectedTab = logIndex
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddRecipe, object: nil)
                }
            } else if url.path == "/supplement" {
                if let supplementIndex = selectedTabs.firstIndex(of: .supplements) {
                    selectedTab = supplementIndex
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddSupplement, object: nil)
                }
            }
        case "scan":
            if let logIndex = selectedTabs.firstIndex(of: .log) {
                selectedTab = logIndex
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .quickScan, object: nil)
            }
        default:
            break
        }
    }
}

#Preview {
    ContentView()
}
