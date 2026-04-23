import SwiftUI
import SwiftData

struct MealListView: View {
    @Query(sort: \MealPrep.createdAt, order: .reverse) private var mealPreps: [MealPrep]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreateSheet = false

    var body: some View {
        List {
            ForEach(mealPreps) { mealPrep in
                NavigationLink(value: mealPrep) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mealPrep.title)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text("\(Int(mealPrep.caloriesPerServing.rounded())) cal/serving")
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text("\(mealPrep.servings) serving\(mealPrep.servings == 1 ? "" : "s")")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Meal Preps")
        .overlay {
            if mealPreps.isEmpty {
                ContentUnavailableView(
                    "No Meal Preps",
                    systemImage: "fork.knife",
                    description: Text("Tap + to create your first meal prep.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateMealPrepSheet()
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mealPreps[index])
        }
    }
}

// MARK: - Create Sheet

private struct CreateMealPrepSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var servings = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    TextField("Title (e.g. Chicken & Rice)", text: $title)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...100)
                }
            }
            .navigationTitle("New Meal Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func create() {
        let meal = MealPrep(title: title.trimmingCharacters(in: .whitespaces), servings: servings)
        modelContext.insert(meal)
        dismiss()
    }
}
