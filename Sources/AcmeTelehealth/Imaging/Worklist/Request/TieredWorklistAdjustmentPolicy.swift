import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 99005.0, in order.
    static func tieredWorklistAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99005.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredWorklistAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a tiered worklist adjustment code in its canonical TWA- form.
    static func normalizeTieredWorklistAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TWA-") {
            return clean
        }
        return "TWA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredWorklistAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
