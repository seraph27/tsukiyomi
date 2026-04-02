import Foundation
import SwiftData

@Model
final class TrackerTypeConfig {
    var name: String
    var unit: String
    var colorHex: String
    var order: Int

    init(name: String, unit: String = "", colorHex: String, order: Int = 0) {
        self.name = name
        self.unit = unit
        self.colorHex = colorHex
        self.order = order
    }

    static let defaults: [(name: String, unit: String, colorHex: String)] = [
        ("Pushup", "", "89b4fa"),
        ("Squat", "", "a6e3a1"),
        ("Protein", "g", "fab387"),
        ("Water", "", "89dceb"),
        ("Problems", "", "cba6f7")
    ]
}
