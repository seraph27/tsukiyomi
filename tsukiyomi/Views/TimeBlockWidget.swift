import SwiftUI
import SwiftData
import Combine

struct TimeBlockWidget: View {
    @Query(sort: \TimeBlock.startHour) private var timeBlocks: [TimeBlock]
    @Query(sort: \PomodoroSession.date, order: .reverse) private var pomodoroSessions: [PomodoroSession]
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var now = Date()
    @State private var pomoDuration = 30

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let pomoDurations = [5, 15, 30, 60, 90]

    private var todayBlocks: [TimeBlock] {
        let weekday = Calendar.current.component(.weekday, from: now)
        return timeBlocks.filter { $0.isActiveOn(weekday: weekday) }
    }

    private var currentBlock: TimeBlock? {
        todayBlocks.first { $0.isActive(at: now) }
    }

    private var nextBlock: TimeBlock? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        return todayBlocks.first { $0.startTotalMinutes > totalMinutes }
    }

    private var todayPomoCount: Int {
        let start = Calendar.current.logicalDayStart(for: .now)
        return pomodoroSessions.filter { $0.date >= start }.count
    }

    var body: some View {
        VStack(spacing: 6) {
            if let current = currentBlock {
                HStack {
                    Circle()
                        .fill(Color(hex: current.colorHex))
                        .frame(width: 8, height: 8)
                    Text("now")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                    Text(current.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.text)
                    Spacer()
                    Text("\(current.formattedStartTime) – \(current.formattedEndTime)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: current.colorHex).opacity(0.15))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: current.colorHex))
                            .frame(width: geo.size.width * current.progress(at: now), height: 3)
                    }
                }
                .frame(height: 3)
            } else {
                HStack {
                    Circle()
                        .fill(CatppuccinMocha.surface2)
                        .frame(width: 8, height: 8)
                    Text("free time")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay1)
                    Spacer()
                }
            }

            if let next = nextBlock {
                HStack(spacing: 4) {
                    Text(">")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    Text("next:")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                    Text(next.name)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.subtext0)
                    Spacer()
                    Text(next.formattedStartTime)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.overlay0)
                }
            }

            // Pomodoro
            HStack(spacing: 6) {
                if appState.pomodoroActive {
                    Text("pomo")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.red)
                    Text(appState.pomodoroDisplay ?? "")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CatppuccinMocha.text)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(CatppuccinMocha.red.opacity(0.15))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(CatppuccinMocha.red)
                                .frame(width: geo.size.width * appState.pomodoroProgress, height: 3)
                        }
                    }
                    .frame(height: 3)

                    Button {
                        appState.cancelPomodoro()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundColor(CatppuccinMocha.overlay0)
                    }
                    .buttonStyle(.plain)
                } else {
                    if todayPomoCount > 0 {
                        Text("\(todayPomoCount) done")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.red.opacity(0.4))
                    }
                    Spacer()
                    Button {
                        let next = pomoDurations.firstIndex(of: pomoDuration)
                            .map { pomoDurations[($0 + 1) % pomoDurations.count] } ?? 25
                        pomoDuration = next
                    } label: {
                        Text("\(pomoDuration)m")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.red.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.startPomodoro(
                            minutes: pomoDuration,
                            category: currentBlock?.category ?? ""
                        )
                    } label: {
                        Text("start")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(CatppuccinMocha.red.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CatppuccinMocha.red.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(CatppuccinMocha.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        .onReceive(timer) { _ in
            now = Date()
        }
        .onChange(of: appState.pomodoroJustCompleted) { _, completed in
            if completed {
                modelContext.insert(PomodoroSession(
                    duration: appState.pomodoroDuration,
                    category: appState.pomodoroCategory
                ))
                appState.pomodoroJustCompleted = false
            }
        }
    }
}
