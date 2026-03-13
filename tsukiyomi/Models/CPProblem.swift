import Foundation
import SwiftData

@Model
final class CPProblem {
    var title: String
    var url: String
    var platform: String
    var completed: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String, url: String, platform: String = "", completed: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.url = url
        self.platform = platform
        self.completed = completed
        self.createdAt = createdAt
    }
}
