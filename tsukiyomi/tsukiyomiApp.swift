import SwiftUI
import SwiftData

@main
struct tsukiyomiApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            TimeBlock.self,
            TodoItem.self,
            CPProblem.self,
            TrackerEntry.self,
            TrackerTypeConfig.self
        ])
        do {
            container = try ModelContainer(for: schema)
            seedDefaultTrackers()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainMenuView()
                .modelContainer(container)
        } label: {
            Text("月")
                .font(.system(size: 13, weight: .semibold, design: .serif))
        }
        .menuBarExtraStyle(.window)
    }

    private func seedDefaultTrackers() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TrackerTypeConfig>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for (i, def) in TrackerTypeConfig.defaults.enumerated() {
            context.insert(TrackerTypeConfig(name: def.name, unit: def.unit, colorHex: def.colorHex, order: i))
        }
        try? context.save()
    }
}
