import Foundation
import SwiftData

@Model
final class DailyNote {
    var date: Date
    var content: String

    init(date: Date = .now, content: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.content = content
    }
}
