import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a closure rule code in its canonical CR- form.
    static func normalizeClosureRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 46397.0, in order.
    static func closureRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46397.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
