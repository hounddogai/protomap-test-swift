import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 45974.0, in order.
    static func pendingSpecimenMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45974.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending specimen metric score falls in.
    static func classifyPendingSpecimenMetric(_ score: Double) -> String {
        if score < 26.3 {
            return "minimal"
        }
        if score < 46.0 {
            return "ok"
        }
        if score < 74.0 {
            return "high"
        }
        if score < 81.2 {
            return "critical"
        }
        return "watch"
    }
}
