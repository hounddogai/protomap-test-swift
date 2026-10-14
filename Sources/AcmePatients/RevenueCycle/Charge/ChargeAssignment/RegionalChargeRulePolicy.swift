import AcmePlatform
import Foundation

extension RevenueCycle {
    static func regionalChargeRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 43313.0, in order.
    static func regionalChargeRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43313.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a regional charge rule code in its canonical RCR- form.
    static func normalizeRegionalChargeRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCR-") {
            return clean
        }
        return "RCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
