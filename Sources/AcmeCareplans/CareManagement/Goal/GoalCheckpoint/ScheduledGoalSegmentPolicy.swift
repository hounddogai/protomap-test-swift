import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeScheduledGoalSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled goal segment score falls in.
    static func classifyScheduledGoalSegment(_ score: Double) -> String {
        if score < 26.4 {
            return "low"
        }
        if score < 61.0 {
            return "medium"
        }
        if score < 69.3 {
            return "high"
        }
        if score < 72.9 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 92122.0, in order.
    static func scheduledGoalSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92122.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledGoalSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
