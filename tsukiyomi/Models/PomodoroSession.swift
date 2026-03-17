import Foundation
import SwiftData

@Model
final class PomodoroSession {
    var date: Date
    var duration: Int
    var category: String

    init(date: Date = .now, duration: Int = 25, category: String = "") {
        self.date = date
        self.duration = duration
        self.category = category
    }
}
