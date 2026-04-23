import SwiftUI

struct IngredientRow: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)
                Text("\(Int(ingredient.gramsUsed))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(ingredient.calories.rounded())) kcal")
                    .font(.body)
                    .fontWeight(.medium)
                Text("P \(formatted(ingredient.protein))  C \(formatted(ingredient.carbs))  F \(formatted(ingredient.fat))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1fg", value)
    }
}
