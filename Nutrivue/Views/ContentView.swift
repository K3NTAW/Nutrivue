//
//  ContentView.swift
//  Nutrivue
//
//  Created by Kenta Waibel on 17.09.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [User]
    @Query(sort: \Meal.date) private var meals: [Meal]
    @State private var showOnboarding = false
    
    private var todaysMeals: [Meal] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
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
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }

                RecipesView()
                    .tabItem {
                        Label("Recipes", systemImage: "book")
                    }

                LogView()
                    .tabItem {
                        Label("Log", systemImage: "plus.circle")
                    }

                SupplementsView()
                    .tabItem {
                        Label("Supplements", systemImage: "pills")
                    }

                SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .onAppear(perform: createTodaysMealsIfNeeded)
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
}

#Preview {
    ContentView()
}
