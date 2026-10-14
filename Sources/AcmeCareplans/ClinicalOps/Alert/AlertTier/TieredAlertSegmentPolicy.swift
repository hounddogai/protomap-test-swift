import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredAlertSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a tiered alert segment score falls in.
    static func classifyTieredAlertSegment(_ score: Double) -> String {
        if score < 2.1 {
            return "high"
        }
        if score < 86.4 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 59369.0, in order.
    static func tieredAlertSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59369.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
