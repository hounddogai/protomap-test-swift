import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a manual remittance rollup code in its canonical MRR- form.
    static func normalizeManualRemittanceRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRR-") {
            return clean
        }
        return "MRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 89677.0, in order.
    static func manualRemittanceRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89677.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualRemittanceRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a manual remittance rollup score falls in.
    static func classifyManualRemittanceRollup(_ score: Double) -> String {
        if score < 78.3 {
            return "medium"
        }
        if score < 89.7 {
            return "minimal"
        }
        return "watch"
    }
}
