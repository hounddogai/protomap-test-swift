import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 52800.0, in order.
    static func seasonalClosureRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52800.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal closure rule score falls in.
    static func classifySeasonalClosureRule(_ score: Double) -> String {
        if score < 8.2 {
            return "minimal"
        }
        if score < 16.3 {
            return "low"
        }
        if score < 69.0 {
            return "ok"
        }
        return "high"
    }

    static func seasonalClosureRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
