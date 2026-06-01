import SwiftUI
import SwiftData

struct NavigationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]
    
    @State private var selectedTabs: Set<NavigationTab> = []
    
    private typealias NavigationTab = ContentView.NavigationTab
    
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
                                    Text("Navigation Settings")
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                        .kerning(-0.3)
                                    
                                    Text("Customize your bottom navigation")
                                        .font(.system(size: 17, weight: .medium, design: .default))
                                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                        .opacity(0.85)
                                        .kerning(0.1)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Instructions")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("• Select up to 5 tabs to show in your bottom navigation")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .kerning(0.1)
                                
                                Text("• The Log tab will always be in the middle position")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .kerning(0.1)
                                
                                Text("• At least 3 tabs must be selected")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .kerning(0.1)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Tab Selection
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                
                                Text("Available Tabs")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                                    .kerning(0.3)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(NavigationTab.allCases) { tab in
                                    NavigationTabRow(
                                        tab: tab,
                                        isSelected: selectedTabs.contains(tab),
                                        isDisabled: tab == .log || tab == .settings || (selectedTabs.count >= 5 && !selectedTabs.contains(tab))
                                    ) {
                                        toggleTab(tab)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                saveSettings()
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Save Settings")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: DesignSystem.Colors.accent.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .disabled(selectedTabs.count < 3)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func toggleTab(_ tab: NavigationTab) {
        if tab == .log || tab == .settings { return } // Log and Settings tabs are always selected
        
        if selectedTabs.contains(tab) {
            if selectedTabs.count > 3 { // Ensure minimum 3 tabs
                selectedTabs.remove(tab)
            }
        } else {
            if selectedTabs.count < 5 { // Maximum 5 tabs
                selectedTabs.insert(tab)
            }
        }
    }
    
    private func loadSettings() {
        // Load from UserDefaults or user preferences
        let savedTabs = UserDefaults.standard.stringArray(forKey: "selectedNavigationTabs") ?? []
        selectedTabs = Set(savedTabs.compactMap { NavigationTab(rawValue: $0) })
        
        // Ensure log and settings are always selected
        selectedTabs.insert(.log)
        selectedTabs.insert(.settings)
        
        // If no saved settings, use default selection
        if selectedTabs.count < 3 {
            selectedTabs = [.dashboard, .log, .settings]
        }
    }
    
    private func saveSettings() {
        let tabStrings = selectedTabs.map { $0.rawValue }
        UserDefaults.standard.set(tabStrings, forKey: "selectedNavigationTabs")
        
        // Post notification to refresh the navigation
        NotificationCenter.default.post(name: .navigationSettingsChanged, object: nil)
    }
}

private struct NavigationTabRow: View {
    let tab: ContentView.NavigationTab
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(tab.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(tab.color.opacity(isSelected ? 1.0 : 0.6))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.rawValue)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                        .kerning(0.1)
                    
                    if tab == .log {
                        Text("Always in middle")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            .kerning(0.1)
                            .padding(.bottom, 4)
                    } else if tab == .settings {
                        Text("Always visible")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                            .kerning(0.1)
                            .padding(.bottom, 4)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.Colors.adaptiveCardBackground())
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? DesignSystem.Colors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: .black.opacity(0.06),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview {
    NavigationSettingsView()
}
