# Nutrivue

A modern, mobile‑first iOS app for logging food, tracking supplements, and staying on top of your nutrition goals. Built with SwiftUI and SwiftData, with clean design principles and a focus on day‑to‑day usability.

## Overview

- Log meals quickly with search or barcode scanning
- Create reusable recipes from multiple ingredients
- Track supplements with reminders and adherence
- See progress at a glance on the dashboard
- Personalize goals (maintain/lose/gain/muscle) with dynamic macros
- Metric and Imperial units throughout (g/oz, kg/lb)

## Core Features

### Food Logging
- Global Add flow: tap +, choose the meal (Breakfast/Lunch/Dinner/Snacks), then choose Add Food or Add Recipe.
- Search (OpenFoodFacts):
  - Live search with ranking and deduplication (by barcode), image previews, recent/favorites, and query highlighting.
  - Select a product to open Adjust Serving, with an editable grams field and calculated nutrition.
- Barcode Scanning:
  - Uses VisionKit to scan; shows loading overlay, error and not‑found states.
  - On success, opens the same Adjust Serving sheet as search.
- Unit‑aware display:
  - Calories shown in kcal.
  - Macros shown in grams (metric) or ounces (imperial).

### Recipes
- Build a recipe from multiple ingredients.
- Add ingredients via search or barcode scan, then confirm grams with the Adjust Serving sheet (same UX as food logging).
- App stores per‑100g nutrition snapshots for stability and accurate totals over time.
- Add a recipe to any meal with a servings adjust step; logs as a single food item with aggregated macros.

### Supplements
- Create supplements with daily/weekly schedules (supports multiple weekdays) and an optional time of day.
- Dashboard “Supplements Today” shows due items as clean cards; tap to mark as taken.
- Dedicated Supplements tab lists all supplements with delete support.
- Local notifications at scheduled times; reminders use weekday schedules.

### Dashboard
- Calorie progress ring:
  - Primary ring up to goal (accent color).
  - Red ring shows how far over goal you are.
- Macro bars (Protein/Carbs/Fat):
  - Turn red when you exceed the daily goal; display an “Over by …” value.
  - Protein uses a non‑red base color (purple) to avoid confusion.
- Mobile‑first layout with clean typography and high contrast.

### History (Overview)
- Minimal history overview with range picker (7/14/30d):
  - Calories chart with a goal range band (±5%).
  - Adherence row (check/miss/none) per day.
- Designed to remain lightweight and not clutter the dashboard.

### Settings
- Integrations:
  - Apple Health authorization check at launch; sync latest weight and active energy.
- Preferences:
  - Units (Metric/Imperial) affect weight and macro units across the app.
  - Dietary notes.
- Goals:
  - Choose intent: Maintain / Lose / Gain / Build Muscle.
  - Goals recalculate calories and macronutrients based on BMR (Mifflin‑St Jeor), activity level, and goal.
  - Values update live in Settings and propagate throughout the app.
- Notifications: toggle and schedule meal reminders (optional).

## Design Principles

- Mobile‑first, minimal UI: clear hierarchy, ample spacing, clean typography.
- Consistency:
  - One Adjust Serving sheet style used across Food and Recipe flows.
  - Shared search experience with images, favorites, and recents.
- Accessibility:
  - Descriptive labels, hints, and clear color states for overages.
- Performance:
  - Search result deduplication (by barcode) and ranking.
  - In‑memory caching for product lookups and search.

## Architecture

- SwiftUI for UI, SwiftData for persistence.
- Models: `User`, `Goals`, `Meal`, `FoodItem`, `Supplement`, `SupplementIntake`, `Recipe`, `RecipeIngredient`.
- ViewModels/Services:
  - `FoodSearchViewModel`: live search with debouncing, ranking, favorites/recents cache.
  - `FoodLookupViewModel`: barcode product lookup with overlay/error states.
  - `SettingsViewModel`: notifications, HealthKit, and preference management.
  - `APIService`: OpenFoodFacts queries (search/product).
  - `NotificationService`: meal/supplement scheduling.
  - `HealthKitService`: authorization and read for weight/active energy.
  - `GoalService`: BMR/TDEE and goal‑based macro calculations.

## Data & Persistence

- SwiftData model container includes all models, with relationships:
  - `Meal` has many `FoodItem`.
  - `Recipe` has many `RecipeIngredient`.
  - `Supplement` has many `SupplementIntake`.
- Migrations:
  - `Goals.goalTypeRaw` is optional to support older stores.
  - `Supplement` uses a weekday bitmask for specific days to ensure stable persistence.

## UX Flows

- Add (+) → Select Meal → Choose Add Food or Add Recipe.
- Add Food:
  - Search or Scan → Adjust Serving → Save to selected meal.
- Add Recipe:
  - Build or pick recipe → Adjust servings → Save to selected meal.
- Supplements:
  - Create schedules; dashboard shows due items; tab lists all for management.

## Privacy & Intent

Nutrivue is designed to help users maintain a healthy relationship with food and supplements through clarity and gentle guidance—not guilt. Data stays local; external services are used only for product lookups and Apple frameworks for health and notifications.

## Roadmap Ideas

- Edit/duplicate food items in place.
- Export history (CSV/PDF) and deeper charts.
- Tags for recipes/supplements and smart grouping.
- Optional HealthKit write for weight or nutrition (user‑controlled).

## Development

- Xcode 15+, iOS 17+ (VisionKit, SwiftData, SwiftUI).
- OpenFoodFacts API for product data (no auth required for basic usage).
- Ensure camera permission for scanning and notification permission for reminders.

---

Questions or suggestions? File an issue or start a discussion.
