import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a global priority record code in its canonical GPR- form.
    static func normalizeGlobalPriorityRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPR-") {
            return clean
        }
        return "GPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalPriorityRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 86315.0, in order.
    static func globalPriorityRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 86315.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalPriorityRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
