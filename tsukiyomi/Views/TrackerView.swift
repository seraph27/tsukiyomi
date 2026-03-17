import SwiftUI
import SwiftData

struct TrackerView: View {
    @Query(sort: \TrackerTypeConfig.order) private var trackerTypes: [TrackerTypeConfig]
    @Query private var entries: [TrackerEntry]
    @Environment(\.modelContext) private var modelContext
    @Binding var currentView: AppView
    @State private var inputText = ""
    @State private var selectedIndex = 0

    private func todayTotal(for typeName: String) -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        return entries
            .filter { $0.type == typeName && calendar.startOfDay(for: $0.date) == startOfDay }
            .reduce(0) { $0 + $1.effectiveValue }
    }

    private var selectedType: TrackerTypeConfig? {
        guard selectedIndex < trackerTypes.count else { return nil }
        return trackerTypes[selectedIndex]
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("tracker")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(CatppuccinMocha.subtext0)
                Spacer()
                Button {
                    currentView = .trackerConfig
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10))
                        .foregroundColor(CatppuccinMocha.overlay0)
                }
                .buttonStyle(.plain)
            }

            let columns = trackerTypes.count <= 4
                ? [GridItem(.flexible()), GridItem(.flexible())]
                : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(trackerTypes.enumerated()), id: \.element.id) { index, type in
                    let isSelected = selectedIndex == index
                    let color = Color(hex: type.colorHex)

                    VStack(spacing: 2) {
                        Text(TrackerEntry.formatValue(todayTotal(for: type.name), unit: type.unit))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Text(type.name.lowercased())
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? color.opacity(0.18) : color.opacity(0.06))
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(color.opacity(0.4), lineWidth: 1)
                        }
                    }
                    .foregroundColor(color)
                    .onTapGesture { selectedIndex = index }
                }
            }

            if let sel = selectedType {
                HStack(spacing: 4) {
                    Text(sel.name.lowercased())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(hex: sel.colorHex).opacity(0.6))

                    TextField("+0", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.text)
                        .frame(maxWidth: .infinity)
                        .onSubmit { addEntry() }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private func addEntry() {
        guard let sel = selectedType else { return }
        let cleaned = inputText
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "–", with: "-")  // en dash
            .replacingOccurrences(of: "—", with: "-")  // em dash
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value != 0 else {
            inputText = ""
            return
        }
        modelContext.insert(TrackerEntry(type: sel.name, amount: value))
        inputText = ""
    }
}
