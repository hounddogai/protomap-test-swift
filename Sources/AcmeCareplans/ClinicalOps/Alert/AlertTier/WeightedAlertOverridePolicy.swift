import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a weighted alert override code in its canonical WAO- form.
    static func normalizeWeightedAlertOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAO-") {
            return clean
        }
        return "WAO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 28684.0, in order.
    static func weightedAlertOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28684.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWeightedAlertOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted alert override score falls in.
    static func classifyWeightedAlertOverride(_ score: Double) -> String {
        if score < 15.9 {
            return "low"
        }
        if score < 34.2 {
            return "elevated"
        }
        if score < 79.4 {
            return "watch"
        }
        return "medium"
    }
}
