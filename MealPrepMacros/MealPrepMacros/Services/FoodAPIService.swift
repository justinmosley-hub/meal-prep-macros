import Foundation
import SwiftData

struct ScannedFood {
    let name: String
    let nutrition: NutritionInfo
    let barcode: String
}

@MainActor
enum FoodAPIService {
    private static let baseURL = "https://world.openfoodfacts.net/api/v2/product"

    static func lookup(barcode: String, in context: ModelContext) async throws -> ScannedFood? {
        // 1. Check local cache first
        let descriptor = FetchDescriptor<CustomFood>(
            predicate: #Predicate { $0.barcode == barcode }
        )
        if let cached = try context.fetch(descriptor).first {
            return ScannedFood(name: cached.name, nutrition: cached.nutrition, barcode: barcode)
        }

        // 2. Hit Open Food Facts API
        guard let url = URL(string: "\(baseURL)/\(barcode)?fields=product_name,serving_size,nutriments") else {
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else { return nil }

        let nutrition = buildNutrition(from: product)
        return ScannedFood(
            name: product.productName?.isEmpty == false ? product.productName! : "Unknown Item",
            nutrition: nutrition,
            barcode: barcode
        )
    }

    // Use per-serving values when the API provides a parseable gram serving size;
    // fall back to per-100g otherwise.
    private static func buildNutrition(from product: OFFProduct) -> NutritionInfo {
        let n = product.nutriments
        if let servingStr = product.servingSize,
           let servingGrams = parseGrams(from: servingStr),
           servingGrams > 0,
           let cal = n.energyKcalServing,
           let pro = n.proteinsServing,
           let carb = n.carbohydratesServing,
           let fat = n.fatServing {
            return NutritionInfo(
                servingGrams: servingGrams,
                calories: cal,
                protein: pro,
                carbs: carb,
                fat: fat
            )
        }
        // Fallback: per 100g
        return NutritionInfo(
            servingGrams: 100,
            calories: n.energyKcal100g ?? 0,
            protein: n.proteins100g ?? 0,
            carbs: n.carbohydrates100g ?? 0,
            fat: n.fat100g ?? 0
        )
    }

    // Extracts the gram value from strings like "30g", "30 g", "1 serving (30g)", "1 oz (28g)"
    private static func parseGrams(from string: String) -> Double? {
        let pattern = /(\d+(?:\.\d+)?)\s*g/
        guard let match = string.firstMatch(of: pattern) else { return nil }
        return Double(match.1)
    }
}

// MARK: - Open Food Facts response types

private struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let servingSize: String?
    let nutriments: OFFNutriments

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case servingSize = "serving_size"
        case nutriments
    }
}

private struct OFFNutriments: Decodable {
    // Per serving
    let energyKcalServing: Double?
    let proteinsServing: Double?
    let carbohydratesServing: Double?
    let fatServing: Double?
    // Per 100g fallback
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcalServing = "energy-kcal_serving"
        case proteinsServing = "proteins_serving"
        case carbohydratesServing = "carbohydrates_serving"
        case fatServing = "fat_serving"
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
