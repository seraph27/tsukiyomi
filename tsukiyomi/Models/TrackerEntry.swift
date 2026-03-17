import Foundation
import SwiftData

@Model
final class TrackerEntry {
    var type: String
    var count: Int
    var amount: Double = 0
    var date: Date

    var effectiveValue: Double {
        amount != 0 ? amount : Double(count)
    }

    init(type: String, count: Int = 0, amount: Double = 0, date: Date = .now) {
        self.type = type
        self.count = count
        self.amount = amount
        self.date = date
    }

    static func formatValue(_ value: Double, unit: String) -> String {
        if value == 0 { return "0\(unit)" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))\(unit)"
        }
        return String(format: "%.1f%@", value, unit)
    }
}
