import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a global substitution target code in its canonical GST- form.
    static func normalizeGlobalSubstitutionTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GST-") {
            return clean
        }
        return "GST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 46276.0, in order.
    static func globalSubstitutionTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46276.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeGlobalSubstitutionTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalSubstitutionTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
