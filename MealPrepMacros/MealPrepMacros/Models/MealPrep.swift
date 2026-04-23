import SwiftData
import Foundation

@Model
final class MealPrep {
    var title: String
    var createdAt: Date
    var servings: Int

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.mealPrep)
    var ingredients: [Ingredient] = []

    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { ingredients.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double    { ingredients.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double      { ingredients.reduce(0) { $0 + $1.fat } }

    var caloriesPerServing: Double { servings > 0 ? totalCalories / Double(servings) : 0 }
    var proteinPerServing: Double  { servings > 0 ? totalProtein / Double(servings) : 0 }
    var carbsPerServing: Double    { servings > 0 ? totalCarbs / Double(servings) : 0 }
    var fatPerServing: Double      { servings > 0 ? totalFat / Double(servings) : 0 }

    init(title: String, servings: Int = 1) {
        self.title = title
        self.createdAt = Date()
        self.servings = servings
    }
}
