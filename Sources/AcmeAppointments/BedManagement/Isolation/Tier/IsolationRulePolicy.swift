import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation rule code in its canonical IR- form.
    static func normalizeIsolationRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IR-") {
            return clean
        }
        return "IR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func isolationRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func isolationRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 61620.0, in order.
    static func isolationRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61620.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
