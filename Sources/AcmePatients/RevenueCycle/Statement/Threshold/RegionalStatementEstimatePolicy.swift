import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 59550.0, in order.
    static func regionalStatementEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59550.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional statement estimate score falls in.
    static func classifyRegionalStatementEstimate(_ score: Double) -> String {
        if score < 15.2 {
            return "high"
        }
        if score < 38.6 {
            return "medium"
        }
        if score < 60.5 {
            return "critical"
        }
        if score < 66.8 {
            return "watch"
        }
        return "elevated"
    }

    static func regionalStatementEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
