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
    var technique: String = ""
    var notes: String = ""
    var isContest: Bool = false
    var resource: String = ""

    init(title: String, url: String = "", platform: String = "", completed: Bool = false,
         createdAt: Date = .now, technique: String = "", notes: String = "",
         isContest: Bool = false, resource: String = "") {
        self.title = title
        self.url = url
        self.platform = platform
        self.completed = completed
        self.createdAt = createdAt
        self.technique = technique
        self.notes = notes
        self.isContest = isContest
        self.resource = resource
    }
}
