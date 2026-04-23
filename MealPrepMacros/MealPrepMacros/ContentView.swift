import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MealListView()
                .navigationDestination(for: MealPrep.self) { mealPrep in
                    MealDetailView(mealPrep: mealPrep)
                }
        }
    }
}
