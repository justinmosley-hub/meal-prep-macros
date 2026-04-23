import SwiftData
import Foundation

@Model
final class Ingredient {
    var name: String
    var gramsUsed: Double
    var nutrition: NutritionInfo
    var mealPrep: MealPrep?

    private var ratio: Double { nutrition.servingGrams > 0 ? gramsUsed / nutrition.servingGrams : 0 }
    var calories: Double { ratio * nutrition.calories }
    var protein: Double  { ratio * nutrition.protein }
    var carbs: Double    { ratio * nutrition.carbs }
    var fat: Double      { ratio * nutrition.fat }

    init(name: String, gramsUsed: Double, nutrition: NutritionInfo) {
        self.name = name
        self.gramsUsed = gramsUsed
        self.nutrition = nutrition
    }
}
