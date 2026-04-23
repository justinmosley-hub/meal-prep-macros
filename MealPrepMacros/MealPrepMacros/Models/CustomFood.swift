import SwiftData
import Foundation

@Model
final class CustomFood {
    var barcode: String?
    var name: String
    var nutrition: NutritionInfo

    init(barcode: String? = nil, name: String, nutrition: NutritionInfo) {
        self.barcode = barcode
        self.name = name
        self.nutrition = nutrition
    }
}
