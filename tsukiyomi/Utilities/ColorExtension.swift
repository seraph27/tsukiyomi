import SwiftUI

extension Calendar {
    // Days reset at 1am — anything before 1am counts toward the previous calendar day.
    func logicalDayStart(for date: Date) -> Date {
        let midnight = startOfDay(for: date)
        let oneAM = self.date(byAdding: .hour, value: 1, to: midnight)!
        return date < oneAM ? self.date(byAdding: .day, value: -1, to: midnight)! : midnight
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
