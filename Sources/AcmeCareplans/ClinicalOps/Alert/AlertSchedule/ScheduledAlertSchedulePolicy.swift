import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 8839.0, in order.
    static func scheduledAlertScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8839.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledAlertScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func mergeScheduledAlertScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled alert schedule score falls in.
    static func classifyScheduledAlertSchedule(_ score: Double) -> String {
        if score < 2.8 {
            return "elevated"
        }
        if score < 20.9 {
            return "watch"
        }
        if score < 76.1 {
            return "ok"
        }
        return "critical"
    }
}
