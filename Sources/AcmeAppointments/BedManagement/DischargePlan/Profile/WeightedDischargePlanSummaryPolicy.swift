import AcmePlatform
import Foundation

extension BedManagement {
    static func weightedDischargePlanSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a weighted discharge plan summary code in its canonical WDPS- form.
    static func normalizeWeightedDischargePlanSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WDPS-") {
            return clean
        }
        return "WDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 67928.0, in order.
    static func weightedDischargePlanSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWeightedDischargePlanSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
