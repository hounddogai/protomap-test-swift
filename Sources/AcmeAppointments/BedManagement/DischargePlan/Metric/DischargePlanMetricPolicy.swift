import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a discharge plan metric score falls in.
    static func classifyDischargePlanMetric(_ score: Double) -> String {
        if score < 67.4 {
            return "high"
        }
        if score < 84.6 {
            return "watch"
        }
        if score < 87.6 {
            return "low"
        }
        if score < 96.8 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 89997.0, in order.
    static func dischargePlanMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89997.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
