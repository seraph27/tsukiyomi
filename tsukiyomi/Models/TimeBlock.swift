import Foundation
import SwiftData

@Model
final class TimeBlock {
    var name: String
    var category: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var colorHex: String
    var daysActive: String?

    init(name: String, category: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, colorHex: String, daysActive: String = "") {
        self.name = name
        self.category = category
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.colorHex = colorHex
        self.daysActive = daysActive
    }

    var startTotalMinutes: Int { startHour * 60 + startMinute }
    var endTotalMinutes: Int { endHour * 60 + endMinute }

    var formattedStartTime: String {
        Self.formatTime(hour: startHour, minute: startMinute)
    }

    var formattedEndTime: String {
        Self.formatTime(hour: endHour, minute: endMinute)
    }

    private var days: String { daysActive ?? "" }

    var activeDaySet: Set<Int> {
        guard !days.isEmpty else { return [] }
        return Set(days.split(separator: ",").compactMap { Int($0) })
    }

    var isEveryDay: Bool { days.isEmpty }

    func isActiveOn(weekday: Int) -> Bool {
        days.isEmpty || activeDaySet.contains(weekday)
    }

    func isActive(at date: Date = .now) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        guard isActiveOn(weekday: weekday) else { return false }
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute
        return totalMinutes >= startTotalMinutes && totalMinutes < endTotalMinutes
    }

    func progress(at date: Date = .now) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute
        let duration = endTotalMinutes - startTotalMinutes
        guard duration > 0 else { return 0 }
        return Double(totalMinutes - startTotalMinutes) / Double(duration)
    }

    var daysLabel: String {
        guard !days.isEmpty else { return "daily" }
        let names = ["", "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        let sorted = activeDaySet.sorted()
        if sorted == [2, 3, 4, 5, 6] { return "weekdays" }
        if sorted == [1, 7] { return "weekends" }
        return sorted.map { names[$0] }.joined(separator: " ")
    }

    static func formatTime(hour: Int, minute: Int) -> String {
        let displayHour: Int
        let period: String
        switch hour {
        case 0: displayHour = 12; period = "AM"
        case 1..<12: displayHour = hour; period = "AM"
        case 12: displayHour = 12; period = "PM"
        default: displayHour = hour - 12; period = "PM"
        }
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    static let categoryColors: [String: String] = [
        "work": "89b4fa",
        "gaming": "cba6f7",
        "cp": "f38ba8",
        "workout": "a6e3a1",
        "break": "9399b2",
        "study": "f9e2af",
        "sleep": "b4befe",
        "eat": "fab387",
        "other": "94e2d5"
    ]
}
