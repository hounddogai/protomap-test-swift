import AcmePlatform
import Foundation

extension Imaging {
    static func studySlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func studySlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 68550.0, in order.
    static func studySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68550.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a study slot score falls in.
    static func classifyStudySlot(_ score: Double) -> String {
        if score < 71.4 {
            return "low"
        }
        if score < 99.1 {
            return "high"
        }
        return "elevated"
    }
}
