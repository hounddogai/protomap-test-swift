import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted formulary group code in its canonical WFG- form.
    static func normalizeWeightedFormularyGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WFG-") {
            return clean
        }
        return "WFG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedFormularyGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 18955.0, in order.
    static func weightedFormularyGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18955.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
