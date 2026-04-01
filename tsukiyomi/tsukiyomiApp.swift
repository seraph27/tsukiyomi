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
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainMenuView()
                .environment(appState)
                .modelContainer(container)
        } label: {
            Text("月")
                .font(.system(size: 13, weight: .semibold, design: .serif))
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
