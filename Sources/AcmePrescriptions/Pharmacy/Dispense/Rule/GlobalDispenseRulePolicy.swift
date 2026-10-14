import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalDispenseRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 70452.0, in order.
    static func globalDispenseRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70452.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalDispenseRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a global dispense rule code in its canonical GDR- form.
    static func normalizeGlobalDispenseRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDR-") {
            return clean
        }
        return "GDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
