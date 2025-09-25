//
//  NourivoWidgetsBundle.swift
//  NourivoWidgets
//
//  Created by Kenta Waibel on 18.09.2025.
//

import WidgetKit
import SwiftUI

@main
struct NourivoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuickAddWidget()
        MacroSummaryWidget()
        NutritionAlertWidget()
        CaloriesProgressWidget()
        DashboardOverviewWidget()
        SupplementsReminderWidget()
    }
}
