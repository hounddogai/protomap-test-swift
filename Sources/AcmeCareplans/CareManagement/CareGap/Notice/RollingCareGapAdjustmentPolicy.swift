import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeRollingCareGapAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 34019.0, in order.
    static func rollingCareGapAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34019.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingCareGapAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a rolling care gap adjustment score falls in.
    static func classifyRollingCareGapAdjustment(_ score: Double) -> String {
        if score < 54.3 {
            return "watch"
        }
        if score < 79.6 {
            return "medium"
        }
        return "critical"
    }
}
