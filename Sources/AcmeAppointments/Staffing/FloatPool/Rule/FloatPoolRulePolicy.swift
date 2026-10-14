import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 31487.0, in order.
    static func floatPoolRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31487.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func floatPoolRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func floatPoolRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
