import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Bindable var mealPrep: MealPrep
    @Environment(\.modelContext) private var modelContext
    @State private var showScanner = false
    @State private var showManualEntry = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                macroSummary
                Divider()
                ingredientsList
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(mealPrep.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(mealPrep: mealPrep)
        }
        .sheet(isPresented: $showManualEntry) {
            IngredientFormView(mealPrep: mealPrep, scannedFood: nil, barcode: nil)
        }
    }

    // MARK: - Macro Summary

    private var macroSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Per Serving")
                        .font(.headline)
                    Text("\(mealPrep.servings) serving\(mealPrep.servings == 1 ? "" : "s") total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Stepper("", value: $mealPrep.servings, in: 1...100)
                    .labelsHidden()
                    .overlay(
                        Text("\(mealPrep.servings)")
                            .font(.body.monospacedDigit())
                            .padding(.trailing, 80),
                        alignment: .trailing
                    )
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                MacroCard(label: "Calories", value: mealPrep.caloriesPerServing, unit: "kcal", color: .orange)
                MacroCard(label: "Protein",  value: mealPrep.proteinPerServing,  unit: "g",    color: .blue)
                MacroCard(label: "Carbs",    value: mealPrep.carbsPerServing,    unit: "g",    color: .green)
                MacroCard(label: "Fat",      value: mealPrep.fatPerServing,      unit: "g",    color: .yellow)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Ingredients List

    private var ingredientsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
                .padding(.horizontal)

            if mealPrep.ingredients.isEmpty {
                Text("No ingredients yet — add some below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(mealPrep.ingredients) { ingredient in
                        IngredientRow(ingredient: ingredient)
                            .padding(.horizontal)
                        if ingredient.id != mealPrep.ingredients.last?.id {
                            Divider().padding(.leading)
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.separator, lineWidth: 0.5)
                )
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button {
                    showScanner = true
                } label: {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showManualEntry = true
                } label: {
                    Label("Add Manually", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            if !mealPrep.ingredients.isEmpty {
                totalsRow
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Totals Row

    private var totalsRow: some View {
        HStack {
            Text("Total")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(mealPrep.totalCalories.rounded())) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("P \(formatted(mealPrep.totalProtein))  C \(formatted(mealPrep.totalCarbs))  F \(formatted(mealPrep.totalFat))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1fg", value)
    }
}
