//
//  ContentView.swift
//  Nourivo
//
//  Created by Kenta Waibel on 17.09.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Log Tab
            LogView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "plus.circle.fill" : "plus.circle")
                    Text("Log")
                }
                .tag(1)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("History")
                }
                .tag(2)
            
            // Recipes Tab
            RecipesView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "book.fill" : "book")
                    Text("Recipes")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView(viewModel: SettingsViewModel(modelContext: ModelContext(try! ModelContainer(for: User.self))))
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(DesignSystem.Colors.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self], inMemory: true)
}
