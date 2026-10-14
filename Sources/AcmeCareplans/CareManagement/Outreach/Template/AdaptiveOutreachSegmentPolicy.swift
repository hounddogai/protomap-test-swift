import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive outreach segment score falls in.
    static func classifyAdaptiveOutreachSegment(_ score: Double) -> String {
        if score < 13.1 {
            return "watch"
        }
        if score < 32.0 {
            return "elevated"
        }
        if score < 82.8 {
            return "critical"
        }
        if score < 98.7 {
            return "high"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 74680.0, in order.
    static func adaptiveOutreachSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74680.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
