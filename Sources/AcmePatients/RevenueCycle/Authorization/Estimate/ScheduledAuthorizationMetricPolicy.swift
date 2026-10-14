import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 62406.0, in order.
    static func scheduledAuthorizationMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62406.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled authorization metric score falls in.
    static func classifyScheduledAuthorizationMetric(_ score: Double) -> String {
        if score < 12.1 {
            return "minimal"
        }
        if score < 65.7 {
            return "critical"
        }
        if score < 76.1 {
            return "high"
        }
        return "medium"
    }
}
