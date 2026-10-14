import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime rule code in its canonical OR- form.
    static func normalizeOvertimeRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OR-") {
            return clean
        }
        return "OR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func overtimeRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 12163.0, in order.
    static func overtimeRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12163.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
