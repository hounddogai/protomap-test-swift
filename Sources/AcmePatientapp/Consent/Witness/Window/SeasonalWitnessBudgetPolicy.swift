import AcmePlatform
import Foundation

extension Consent {
    /// Puts a seasonal witness budget code in its canonical SWB- form.
    static func normalizeSeasonalWitnessBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWB-") {
            return clean
        }
        return "SWB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalWitnessBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 94877.0, in order.
    static func seasonalWitnessBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94877.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
