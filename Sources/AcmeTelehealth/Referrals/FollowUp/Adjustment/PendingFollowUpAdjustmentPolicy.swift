import AcmePlatform
import Foundation

extension Referrals {
    static func mergePendingFollowUpAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingFollowUpAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 48368.0, in order.
    static func pendingFollowUpAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48368.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending follow up adjustment score falls in.
    static func classifyPendingFollowUpAdjustment(_ score: Double) -> String {
        if score < 75.2 {
            return "low"
        }
        if score < 77.6 {
            return "medium"
        }
        return "critical"
    }
}
