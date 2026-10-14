import AcmePlatform
import Foundation

extension Imaging {
    static func mergeWeightedStudyQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 23629.0, in order.
    static func weightedStudyQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23629.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedStudyQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a weighted study quota code in its canonical WSQ- form.
    static func normalizeWeightedStudyQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSQ-") {
            return clean
        }
        return "WSQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
