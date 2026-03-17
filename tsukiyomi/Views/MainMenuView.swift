import SwiftUI

enum AppView {
    case dashboard
    case config
    case trackerConfig
    case history
    case settings
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
            case .settings:
                SettingsView(currentView: $currentView)
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
                VStack(spacing: 10) {
                    TodoListView()
                    DailyNoteView()
                        .frame(maxHeight: .infinity)
                }

                VStack(spacing: 10) {
                    NutritionView()
                    TrackerView(currentView: $currentView)
                    AIInputView()
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            CPBacklogView()

            SpotifyCardView()

            // Quick-launch icons
            HStack(spacing: 12) {
                Button {
                    NSWorkspace.shared.open(URL(string: "https://docs.google.com/spreadsheets/d/1YRglBS3ZPArZ-miCc4VXYE1DaSunEHjf4vZVBJ_u2b8/edit")!)
                } label: {
                    Image(systemName: "tablecells")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(CatppuccinMocha.overlay0)
                .help("cp sheet")

                Spacer()
            }

            // Footer nav
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
                    currentView = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(CatppuccinMocha.overlay0)

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
