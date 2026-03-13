import Foundation
import SwiftData

@Model
final class TrackerEntry {
    var type: String
    var count: Int
    var date: Date

    init(type: String, count: Int, date: Date = .now) {
        self.type = type
        self.count = count
        self.date = date
    }
}
