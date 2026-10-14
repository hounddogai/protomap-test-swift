import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a cleaning summary code in its canonical CS- form.
    static func normalizeCleaningSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 85413.0, in order.
    static func cleaningSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85413.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
