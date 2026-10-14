import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func authorizationPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 4910.0, in order.
    static func authorizationPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4910.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a authorization policy score falls in.
    static func classifyAuthorizationPolicy(_ score: Double) -> String {
        if score < 43.5 {
            return "minimal"
        }
        if score < 62.7 {
            return "medium"
        }
        if score < 90.7 {
            return "critical"
        }
        return "elevated"
    }
}
