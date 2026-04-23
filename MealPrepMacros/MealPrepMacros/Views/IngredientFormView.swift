import SwiftUI
import SwiftData
import VisionKit

// MARK: - Barcode Scanner Sheet

struct BarcodeScannerSheet: View {
    let mealPrep: MealPrep
    @Environment(\.modelContext) private var modelContext

    private enum Phase {
        case scanning
        case loading
        case form(ScannedFood?, String)
    }

    @State private var phase: Phase = .scanning

    var body: some View {
        switch phase {
        case .scanning:
            scanningView
        case .loading:
            ProgressView("Looking up barcode…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .form(let food, let barcode):
            IngredientFormView(mealPrep: mealPrep, scannedFood: food, barcode: barcode)
        }
    }

    private var scanningView: some View {
        ZStack(alignment: .bottom) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                IngredientScannerView { barcode in
                    handleScan(barcode)
                }
                .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Scanner Not Available",
                    systemImage: "barcode.viewfinder",
                    description: Text("This device doesn't support the barcode scanner.")
                )
            }

            Text("Point the camera at a barcode")
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 40)
        }
    }

    private func handleScan(_ barcode: String) {
        phase = .loading
        Task {
            let result = try? await FoodAPIService.lookup(barcode: barcode, in: modelContext)
            phase = .form(result, barcode)
        }
    }
}

// MARK: - Ingredient Form View

struct IngredientFormView: View {
    let mealPrep: MealPrep
    let scannedFood: ScannedFood?
    let barcode: String?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var gramsText: String = ""
    @State private var servingSizeText: String   // only used for manual entry
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String

    private var isManualEntry: Bool { scannedFood == nil }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              (Double(gramsText) ?? 0) > 0 else { return false }
        if isManualEntry {
            return (Double(servingSizeText) ?? 0) > 0
        }
        return true
    }

    // Live macro preview based on grams entered
    private var servingGrams: Double {
        isManualEntry ? (Double(servingSizeText) ?? 0) : 100
    }

    private func previewMacro(_ perServing: Double) -> String {
        guard servingGrams > 0, let grams = Double(gramsText), grams > 0 else { return "—" }
        let value = (grams / servingGrams) * perServing
        return value < 10 ? String(format: "%.1f", value) : String(Int(value.rounded()))
    }

    init(mealPrep: MealPrep, scannedFood: ScannedFood?, barcode: String?) {
        self.mealPrep = mealPrep
        self.scannedFood = scannedFood
        self.barcode = barcode
        _name = State(initialValue: scannedFood?.name ?? "")
        _servingSizeText = State(initialValue: "")
        _caloriesText = State(initialValue: scannedFood.map { macroString($0.nutrition.calories) } ?? "")
        _proteinText  = State(initialValue: scannedFood.map { macroString($0.nutrition.protein) } ?? "")
        _carbsText    = State(initialValue: scannedFood.map { macroString($0.nutrition.carbs) } ?? "")
        _fatText      = State(initialValue: scannedFood.map { macroString($0.nutrition.fat) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Ingredient name + how many grams used
                Section("Ingredient") {
                    TextField("Name", text: $name)
                    HStack {
                        TextField("Grams used", text: $gramsText)
                            .keyboardType(.decimalPad)
                        Text("g").foregroundStyle(.secondary)
                    }
                }

                // Serving size — only needed for manual entry
                if isManualEntry {
                    Section {
                        HStack {
                            TextField("Serving size", text: $servingSizeText)
                                .keyboardType(.decimalPad)
                            Text("g").foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Label Serving Size")
                    } footer: {
                        Text("Enter the serving size printed on your nutrition label, then enter the macros for that serving below.")
                    }
                }

                // Nutrition values for the reference serving
                Section {
                    macroField("Calories", text: $caloriesText, unit: "kcal")
                    macroField("Protein",  text: $proteinText,  unit: "g")
                    macroField("Carbs",    text: $carbsText,    unit: "g")
                    macroField("Fat",      text: $fatText,      unit: "g")
                } header: {
                    Text(isManualEntry ? "Nutrition per Serving" : "Nutrition per 100g")
                } footer: {
                    if isManualEntry {
                        Text("This will be saved so future scans of the same barcode are filled in automatically.")
                    }
                }

                // Live calculation preview
                if (Double(gramsText) ?? 0) > 0 && servingGrams > 0 {
                    Section("Calculated for \(gramsText)g") {
                        macroPreviewRow("Calories", value: previewMacro(Double(caloriesText) ?? 0), unit: "kcal")
                        macroPreviewRow("Protein",  value: previewMacro(Double(proteinText) ?? 0),  unit: "g")
                        macroPreviewRow("Carbs",    value: previewMacro(Double(carbsText) ?? 0),    unit: "g")
                        macroPreviewRow("Fat",      value: previewMacro(Double(fatText) ?? 0),      unit: "g")
                    }
                }
            }
            .navigationTitle(isManualEntry ? "Add Manually" : "Confirm Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    @ViewBuilder
    private func macroField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 80)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func macroPreviewRow(_ label: String, value: String, unit: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text("\(value) \(unit)")
                .fontWeight(.medium)
        }
    }

    private func save() {
        let refServing = isManualEntry ? (Double(servingSizeText) ?? 100) : 100
        let nutrition = NutritionInfo(
            servingGrams: refServing,
            calories: Double(caloriesText) ?? 0,
            protein:  Double(proteinText)  ?? 0,
            carbs:    Double(carbsText)    ?? 0,
            fat:      Double(fatText)      ?? 0
        )

        if isManualEntry {
            let custom = CustomFood(barcode: barcode, name: name, nutrition: nutrition)
            modelContext.insert(custom)
        }

        let ingredient = Ingredient(
            name: name,
            gramsUsed: Double(gramsText) ?? 0,
            nutrition: nutrition
        )
        modelContext.insert(ingredient)
        mealPrep.ingredients.append(ingredient)
        dismiss()
    }
}

private func macroString(_ value: Double) -> String {
    value == 0 ? "" : String(format: "%g", value)
}
