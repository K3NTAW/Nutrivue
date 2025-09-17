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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, Meal.self, FoodItem.self, Goals.self])
    }
}
