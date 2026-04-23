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
        guard let url = URL(string: "\(baseURL)/\(barcode)?fields=product_name,nutriments") else {
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else { return nil }

        let nutrition = NutritionInfo(
            servingGrams: 100,
            calories: product.nutriments.energyKcal100g ?? 0,
            protein: product.nutriments.proteins100g ?? 0,
            carbs: product.nutriments.carbohydrates100g ?? 0,
            fat: product.nutriments.fat100g ?? 0
        )
        return ScannedFood(
            name: product.productName?.isEmpty == false ? product.productName! : "Unknown Item",
            nutrition: nutrition,
            barcode: barcode
        )
    }
}

// MARK: - Open Food Facts response types

private struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let nutriments: OFFNutriments

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
    }
}

private struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
