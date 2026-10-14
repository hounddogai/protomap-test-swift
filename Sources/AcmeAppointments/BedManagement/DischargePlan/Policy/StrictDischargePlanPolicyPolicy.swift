import AcmePlatform
import Foundation

extension BedManagement {
    static func strictDischargePlanPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 75586.0, in order.
    static func strictDischargePlanPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75586.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictDischargePlanPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
