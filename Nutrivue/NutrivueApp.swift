//
//  NutrivueApp.swift
//  Nutrivue
//
//  Created by Kenta Waibel on 17.09.2025.
//

import SwiftUI
import SwiftData

@main
struct NutrivueApp: App {
    @Environment(\.modelContext) private var modelContext
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Background health sync at app start
                    let sync = HealthSyncService(modelContext: modelContext)
                    sync.syncIfAuthorized()
                    // Write initial widget snapshot
                    if let container = try? ModelContainer(for: User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self) {
                        WidgetSnapshotService(modelContainer: container).writeSnapshot()
                    }
                }
        }
        .modelContainer(for: [User.self, Meal.self, FoodItem.self, Goals.self, Supplement.self, SupplementIntake.self, Recipe.self, RecipeIngredient.self])
    }
}
