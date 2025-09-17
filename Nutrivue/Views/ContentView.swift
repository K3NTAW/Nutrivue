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
    @State private var showOnboarding = false

    var body: some View {
        if users.isEmpty {
            // Show a placeholder while checking for user,
            // and trigger onboarding.
            Color.white.onAppear {
                showOnboarding = true
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(showOnboarding: $showOnboarding)
            }
        } else {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "plus.circle")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calendar")
                    }
                
                SettingsView(viewModel: SettingsViewModel(modelContext: modelContext))
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
