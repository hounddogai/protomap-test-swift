import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 76660.0, in order.
    static func weightedPanelDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76660.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWeightedPanelDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a weighted panel draft code in its canonical WPD- form.
    static func normalizeWeightedPanelDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WPD-") {
            return clean
        }
        return "WPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
