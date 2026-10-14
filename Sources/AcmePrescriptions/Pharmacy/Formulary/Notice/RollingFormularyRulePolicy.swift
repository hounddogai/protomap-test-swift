import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a rolling formulary rule code in its canonical RFR- form.
    static func normalizeRollingFormularyRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFR-") {
            return clean
        }
        return "RFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 54098.0, in order.
    static func rollingFormularyRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54098.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
