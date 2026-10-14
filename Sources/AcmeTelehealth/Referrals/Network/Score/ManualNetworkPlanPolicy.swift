import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 24532.0, in order.
    static func manualNetworkPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24532.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual network plan score falls in.
    static func classifyManualNetworkPlan(_ score: Double) -> String {
        if score < 2.5 {
            return "minimal"
        }
        if score < 15.3 {
            return "medium"
        }
        if score < 43.7 {
            return "elevated"
        }
        if score < 48.1 {
            return "ok"
        }
        return "low"
    }

    static func manualNetworkPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualNetworkPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
