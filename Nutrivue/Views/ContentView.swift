//
//  ContentView.swift
//  Nutrivue
//
//  Created by Kenta Waibel on 17.09.2025.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]
    @Query(sort: \Meal.date) private var meals: [Meal]
    @State private var showOnboarding = false
    @State private var selectedTab: Int = 0
    
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
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                RecipesView()
                    .tabItem {
                        Label("Recipes", systemImage: "book")
                    }
                    .tag(1)
                
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "plus.circle")
                    }
                    .tag(2)
                
                SupplementsView()
                    .tabItem {
                        Label("Supplements", systemImage: "pills")
                    }
                    .tag(3)
                
                SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
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

    private func handleDeepLink(_ url: URL) {
        // nutrivue://add/food, nutrivue://add/recipe, nutrivue://scan, nutrivue://add/supplement
        guard url.scheme == "nutrivue" else { return }
        let path = url.host ?? ""
        switch path {
        case "add":
            if url.path == "/food" {
                selectedTab = 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddFood, object: nil)
                }
            } else if url.path == "/recipe" {
                selectedTab = 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddRecipe, object: nil)
                }
            } else if url.path == "/supplement" {
                selectedTab = 3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .quickAddSupplement, object: nil)
                }
            }
        case "scan":
            selectedTab = 2
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
