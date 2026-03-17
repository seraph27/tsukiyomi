import SwiftUI
import SwiftData

struct NutritionView: View {
    @Query private var entries: [TrackerEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var inputText = ""
    @State private var selectedType = "Calories"
    @FocusState private var focused: Bool

    private let types = [
        ("Calories", "kcal", "f5c2e7"),
        ("Protein", "g", "fab387"),
        ("Fat", "g", "f9e2af"),
        ("Carbs", "g", "a6e3a1"),
    ]

    private func todayTotal(for name: String) -> Double {
        let start = Calendar.current.startOfDay(for: .now)
        return entries
            .filter { $0.type == name && Calendar.current.startOfDay(for: $0.date) == start }
            .reduce(0) { $0 + $1.effectiveValue }
    }

    var body: some View {
        VStack(spacing: 4) {
            // 2x2 grid
            let cols = [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)]
            LazyVGrid(columns: cols, spacing: 3) {
                ForEach(types, id: \.0) { name, unit, hex in
                    let total = todayTotal(for: name)
                    let color = Color(hex: hex)
                    let isSelected = selectedType == name

                    VStack(spacing: 0) {
                        Text(TrackerEntry.formatValue(total, unit: unit))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text(name.lowercased().prefix(4))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? color.opacity(0.18) : color.opacity(0.06))
                    )
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(color.opacity(0.4), lineWidth: 1)
                        }
                    }
                    .foregroundColor(color)
                    .onTapGesture { selectedType = name }
                }
            }

            HStack(spacing: 4) {
                let sel = types.first { $0.0 == selectedType }
                Text(selectedType.lowercased().prefix(4))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(hex: sel?.2 ?? "cdd6f4").opacity(0.6))

                TextField("+0", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(CatppuccinMocha.text)
                    .frame(maxWidth: .infinity)
                    .focused($focused)
                    .onSubmit { addEntry() }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addEntry() {
        let cleaned = inputText
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value != 0 else {
            inputText = ""
            return
        }
        modelContext.insert(TrackerEntry(type: selectedType, amount: value))
        inputText = ""
    }
}
