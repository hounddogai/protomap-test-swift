import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 60369.0, in order.
    static func weightedCensusWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60369.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted census window code in its canonical WCW- form.
    static func normalizeWeightedCensusWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCW-") {
            return clean
        }
        return "WCW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedCensusWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedCensusWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
