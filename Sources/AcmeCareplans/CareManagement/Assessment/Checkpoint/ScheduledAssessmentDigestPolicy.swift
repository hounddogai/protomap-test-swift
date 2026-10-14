import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 78778.0, in order.
    static func scheduledAssessmentDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78778.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledAssessmentDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func scheduledAssessmentDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a scheduled assessment digest score falls in.
    static func classifyScheduledAssessmentDigest(_ score: Double) -> String {
        if score < 22.3 {
            return "elevated"
        }
        if score < 26.6 {
            return "low"
        }
        if score < 57.1 {
            return "minimal"
        }
        if score < 88.8 {
            return "high"
        }
        return "critical"
    }
}
