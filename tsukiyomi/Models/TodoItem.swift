import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var completed: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String, completed: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.completed = completed
        self.createdAt = createdAt
    }
}
