import AcmePlatform
import Foundation

extension ClinicalOps {
    static func scheduledTaskSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 82365.0, in order.
    static func scheduledTaskSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82365.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled task segment score falls in.
    static func classifyScheduledTaskSegment(_ score: Double) -> String {
        if score < 25.3 {
            return "high"
        }
        if score < 48.6 {
            return "minimal"
        }
        return "ok"
    }
}
