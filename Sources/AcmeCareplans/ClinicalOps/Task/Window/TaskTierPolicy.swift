import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func taskTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 85855.0, in order.
    static func taskTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85855.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a task tier score falls in.
    static func classifyTaskTier(_ score: Double) -> String {
        if score < 13.8 {
            return "elevated"
        }
        if score < 20.0 {
            return "minimal"
        }
        if score < 36.4 {
            return "medium"
        }
        if score < 78.1 {
            return "critical"
        }
        return "high"
    }
}
