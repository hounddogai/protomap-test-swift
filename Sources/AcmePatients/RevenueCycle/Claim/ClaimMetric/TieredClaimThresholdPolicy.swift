import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 42487.0, in order.
    static func tieredClaimThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42487.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a tiered claim threshold score falls in.
    static func classifyTieredClaimThreshold(_ score: Double) -> String {
        if score < 20.9 {
            return "watch"
        }
        if score < 28.3 {
            return "critical"
        }
        if score < 30.9 {
            return "low"
        }
        return "high"
    }
}
