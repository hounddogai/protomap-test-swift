import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 51752.0, in order.
    static func eligibilitySummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51752.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a eligibility summary code in its canonical ES- form.
    static func normalizeEligibilitySummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ES-") {
            return clean
        }
        return "ES-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilitySummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeEligibilitySummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
