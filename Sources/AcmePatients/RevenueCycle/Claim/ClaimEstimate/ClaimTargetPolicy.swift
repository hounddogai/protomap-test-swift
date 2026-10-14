import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a claim target score falls in.
    static func classifyClaimTarget(_ score: Double) -> String {
        if score < 34.7 {
            return "ok"
        }
        if score < 35.9 {
            return "critical"
        }
        if score < 51.4 {
            return "minimal"
        }
        if score < 95.2 {
            return "high"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 7406.0, in order.
    static func claimTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7406.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func claimTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
