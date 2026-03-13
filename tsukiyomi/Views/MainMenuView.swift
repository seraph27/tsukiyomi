import SwiftUI

enum AppView {
    case dashboard
    case config
    case trackerConfig
    case history
}

struct MainMenuView: View {
    @State private var currentView: AppView = .dashboard

    var body: some View {
        Group {
            switch currentView {
            case .dashboard:
                DashboardView(currentView: $currentView)
            case .config:
                TimeBlockConfigView(currentView: $currentView)
            case .trackerConfig:
                TrackerConfigView(currentView: $currentView)
            case .history:
                HistoryView(currentView: $currentView)
            }
        }
        .frame(width: 420)
        .background(CatppuccinMocha.base)
    }
}

struct DashboardView: View {
    @Binding var currentView: AppView

    var body: some View {
        VStack(spacing: 10) {
            TimeBlockWidget()

            HStack(alignment: .top, spacing: 10) {
                TodoListView()
                TrackerView(currentView: $currentView)
            }
            .fixedSize(horizontal: false, vertical: true)

            CPBacklogView()

            HStack(spacing: 16) {
                Button {
                    currentView = .config
                } label: {
                    Text("schedule")
                        .font(.system(.caption, design: .monospaced))
                }
                .buttonStyle(.plain)
                .foregroundColor(CatppuccinMocha.overlay1)

                Button {
                    currentView = .history
                } label: {
                    Text("history")
                        .font(.system(.caption, design: .monospaced))
                }
                .buttonStyle(.plain)
                .foregroundColor(CatppuccinMocha.overlay1)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("quit")
                        .font(.system(.caption, design: .monospaced))
                }
                .buttonStyle(.plain)
                .foregroundColor(CatppuccinMocha.overlay0)
            }
        }
        .padding(14)
    }
}
