import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted formulary estimate code in its canonical WFE- form.
    static func normalizeWeightedFormularyEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WFE-") {
            return clean
        }
        return "WFE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedFormularyEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 50607.0, in order.
    static func weightedFormularyEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50607.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
