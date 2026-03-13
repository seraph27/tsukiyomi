import SwiftUI
import SwiftData

struct TrackerConfigView: View {
    @Binding var currentView: AppView
    @Query(sort: \TrackerTypeConfig.order) private var trackerTypes: [TrackerTypeConfig]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newUnit = ""
    @State private var selectedColorIndex = 0

    private let colorOptions: [(name: String, hex: String)] = [
        ("blue", "89b4fa"),
        ("green", "a6e3a1"),
        ("peach", "fab387"),
        ("sky", "89dceb"),
        ("mauve", "cba6f7"),
        ("red", "f38ba8"),
        ("yellow", "f9e2af"),
        ("teal", "94e2d5"),
        ("pink", "f5c2e7"),
        ("lavender", "b4befe")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    currentView = .dashboard
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10))
                        Text("back")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundColor(CatppuccinMocha.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("trackers")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(CatppuccinMocha.text)

                Spacer()

                Button {
                    showingAdd.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundColor(CatppuccinMocha.green)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider().overlay(CatppuccinMocha.surface1)

            ScrollView {
                VStack(spacing: 2) {
                    if trackerTypes.isEmpty {
                        Text("no trackers configured")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.overlay0)
                            .padding(20)
                    }

                    ForEach(trackerTypes) { type in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: type.colorHex))
                                .frame(width: 14, height: 14)

                            Text(type.name)
                                .font(.system(.caption, design: .monospaced).bold())
                                .foregroundColor(CatppuccinMocha.text)

                            if !type.unit.isEmpty {
                                Text("(\(type.unit))")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(CatppuccinMocha.overlay1)
                            }

                            Spacer()

                            Button {
                                modelContext.delete(type)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(CatppuccinMocha.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .frame(maxHeight: 250)

            if showingAdd {
                Divider().overlay(CatppuccinMocha.surface1)

                VStack(spacing: 8) {
                    TextField("name (e.g. Water)", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                    TextField("unit (optional, e.g. g, ml)", text: $newUnit)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(colorOptions.enumerated()), id: \.offset) { index, opt in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: opt.hex))
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        if selectedColorIndex == index {
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(.white.opacity(0.8), lineWidth: 2)
                                        }
                                    }
                                    .onTapGesture { selectedColorIndex = index }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button("add") { addTracker() }
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundColor(CatppuccinMocha.green)
                            .buttonStyle(.plain)

                        Button("cancel") {
                            showingAdd = false
                            newName = ""
                            newUnit = ""
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 380)
        .background(CatppuccinMocha.base.opacity(0.3))
    }

    private func addTracker() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let hex = colorOptions[selectedColorIndex].hex
        let order = trackerTypes.count
        modelContext.insert(TrackerTypeConfig(name: name, unit: newUnit.trimmingCharacters(in: .whitespaces), colorHex: hex, order: order))
        newName = ""
        newUnit = ""
        showingAdd = false
    }
}
