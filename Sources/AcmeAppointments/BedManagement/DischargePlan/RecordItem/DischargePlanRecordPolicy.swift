import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dischargePlanRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 98237.0, in order.
    static func dischargePlanRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98237.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan record score falls in.
    static func classifyDischargePlanRecord(_ score: Double) -> String {
        if score < 49.4 {
            return "elevated"
        }
        if score < 59.7 {
            return "high"
        }
        if score < 65.6 {
            return "watch"
        }
        if score < 74.7 {
            return "low"
        }
        return "critical"
    }
}
