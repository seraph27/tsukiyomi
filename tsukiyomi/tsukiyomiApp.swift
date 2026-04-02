import SwiftUI
import SwiftData
import Carbon.HIToolbox

@main
struct tsukiyomiApp: App {
    private let container: ModelContainer
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    init() {
        let schema = Schema([
            TimeBlock.self,
            TodoItem.self,
            CPProblem.self,
            TrackerEntry.self,
            TrackerTypeConfig.self,
            DailyNote.self,
            PomodoroSession.self
        ])
        do {
            container = try ModelContainer(for: schema)
            seedDefaultTrackers()
            Self.backupStore()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private static func backupStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
              let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let storeURL = appSupport.appendingPathComponent("default.store")
        guard fm.fileExists(atPath: storeURL.path) else { return }

        let backupDir = docs.appendingPathComponent("tsukiyomi_backups")
        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dateStr = fmt.string(from: .now)

        // One backup per day
        for suffix in ["", "-wal", "-shm"] {
            let src = appSupport.appendingPathComponent("default.store\(suffix)")
            let dst = backupDir.appendingPathComponent("backup_\(dateStr)\(suffix)")
            guard fm.fileExists(atPath: src.path), !fm.fileExists(atPath: dst.path) else { continue }
            try? fm.copyItem(at: src, to: dst)
        }

        // Keep last 7 days
        let files = (try? fm.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)) ?? []
        let stores = files.filter { $0.lastPathComponent.hasPrefix("backup_") && !$0.lastPathComponent.hasSuffix("-wal") && !$0.lastPathComponent.hasSuffix("-shm") }
        let sorted = stores.sorted { a, b in
            let aDate = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let bDate = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return aDate < bDate
        }
        for old in sorted.dropLast(7) {
            let base = old.deletingPathExtension().lastPathComponent
            for suffix in ["", "-wal", "-shm"] {
                try? fm.removeItem(at: backupDir.appendingPathComponent("\(base)\(suffix)"))
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainMenuView()
                .environment(appState)
                .modelContainer(container)
        } label: {
            Image("MenuBarIcon")
                .resizable()
                .frame(width: 18, height: 18)
                .clipShape(Circle())
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - App Delegate for Global Hotkey (Cmd+;)

    final class AppDelegate: NSObject, NSApplicationDelegate {
        private var hotkeyRef: EventHotKeyRef?

        func applicationDidFinishLaunching(_ notification: Notification) {
            let hotKeyID = EventHotKeyID(signature: OSType(0x5453554B), id: 1)
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
                DispatchQueue.main.async {
                    let panel = NSApp.windows.first { window in
                        window is NSPanel && String(describing: type(of: window)) != "NSPanel"
                    }
                    if let panel {
                        if panel.isVisible {
                            panel.orderOut(nil)
                        } else {
                            panel.makeKeyAndOrderFront(nil)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    } else {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                return noErr
            }

            InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
            RegisterEventHotKey(
                UInt32(kVK_ANSI_Semicolon), UInt32(cmdKey),
                hotKeyID, GetApplicationEventTarget(), 0, &hotkeyRef
            )

            // Close the panel when the user clicks outside of it.
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: nil,
                queue: .main
            ) { notification in
                guard let window = notification.object as? NSPanel else { return }
                window.orderOut(nil)
            }
        }
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
