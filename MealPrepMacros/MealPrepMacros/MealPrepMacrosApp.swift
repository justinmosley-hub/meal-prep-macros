import SwiftUI
import SwiftData

@main
struct MealPrepMacrosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MealPrep.self, Ingredient.self, CustomFood.self])
    }
}
