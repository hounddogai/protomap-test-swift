import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 45539.0, in order.
    static func scheduledEligibilityPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45539.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeScheduledEligibilityPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledEligibilityPlanSpan(_ start: Int, end: Int) -> Int {
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
