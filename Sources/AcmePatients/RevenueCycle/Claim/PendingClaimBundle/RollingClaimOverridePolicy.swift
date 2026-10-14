import AcmePlatform
import Foundation

extension RevenueCycle {
    static func rollingClaimOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 85570.0, in order.
    static func rollingClaimOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85570.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingClaimOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling claim override score falls in.
    static func classifyRollingClaimOverride(_ score: Double) -> String {
        if score < 11.2 {
            return "critical"
        }
        if score < 44.1 {
            return "watch"
        }
        if score < 46.9 {
            return "medium"
        }
        return "ok"
    }
}
