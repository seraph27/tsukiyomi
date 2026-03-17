import Foundation
import SwiftData
import Combine

@Observable
final class AppState {
    var currentBlockName: String?

    // Pomodoro
    var pomodoroActive = false
    var pomodoroSecondsLeft = 0
    var pomodoroDuration = 25
    var pomodoroCategory = ""
    var pomodoroJustCompleted = false

    private var pomoCancellable: AnyCancellable?
    private var blockCancellable: AnyCancellable?
    private var containerRef: ModelContainer?

    var pomodoroDisplay: String? {
        guard pomodoroActive else { return nil }
        let min = pomodoroSecondsLeft / 60
        let sec = pomodoroSecondsLeft % 60
        return String(format: "%d:%02d", min, sec)
    }

    var pomodoroProgress: Double {
        guard pomodoroActive, pomodoroDuration > 0 else { return 0 }
        let total = Double(pomodoroDuration * 60)
        return 1.0 - Double(pomodoroSecondsLeft) / total
    }

    func startPomodoro(minutes: Int = 25, category: String = "") {
        pomodoroDuration = minutes
        pomodoroSecondsLeft = minutes * 60
        pomodoroCategory = category
        pomodoroActive = true
        pomodoroJustCompleted = false
        pomoCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pomodoroTick()
            }
    }

    func cancelPomodoro() {
        pomoCancellable?.cancel()
        pomoCancellable = nil
        pomodoroActive = false
    }

    private func pomodoroTick() {
        if pomodoroSecondsLeft > 0 {
            pomodoroSecondsLeft -= 1
        } else {
            pomoCancellable?.cancel()
            pomoCancellable = nil
            pomodoroActive = false
            pomodoroJustCompleted = true
        }
    }

    func startBlockUpdates(container: ModelContainer) {
        guard blockCancellable == nil else { return }
        containerRef = container
        updateCurrentBlock()
        blockCancellable = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCurrentBlock()
            }
    }

    private func updateCurrentBlock() {
        guard let containerRef else { return }
        let context = ModelContext(containerRef)
        let descriptor = FetchDescriptor<TimeBlock>(sortBy: [SortDescriptor(\.startHour)])
        guard let blocks = try? context.fetch(descriptor) else { return }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        currentBlockName = blocks.first { $0.isActiveOn(weekday: weekday) && $0.isActive() }?.name
    }
}
