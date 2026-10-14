import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 44057.0, in order.
    static func batchedAuthorizationVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44057.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedAuthorizationVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched authorization variance score falls in.
    static func classifyBatchedAuthorizationVariance(_ score: Double) -> String {
        if score < 6.8 {
            return "minimal"
        }
        if score < 18.5 {
            return "watch"
        }
        if score < 27.7 {
            return "high"
        }
        if score < 98.7 {
            return "low"
        }
        return "elevated"
    }

    static func batchedAuthorizationVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
