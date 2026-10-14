import AcmePlatform
import Foundation

extension Labs {
    /// Puts a default reference range rule code in its canonical DRRR- form.
    static func normalizeDefaultReferenceRangeRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRRR-") {
            return clean
        }
        return "DRRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 83137.0, in order.
    static func defaultReferenceRangeRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83137.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
