import Foundation

struct NutritionInfo: Codable {
    var servingGrams: Double  // reference serving size (100 for API items; user-defined for manual)
    var calories: Double      // kcal per servingGrams
    var protein: Double       // g per servingGrams
    var carbs: Double         // g per servingGrams
    var fat: Double           // g per servingGrams
}
