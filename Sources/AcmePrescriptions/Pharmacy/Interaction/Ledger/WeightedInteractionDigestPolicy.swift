import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a weighted interaction digest score falls in.
    static func classifyWeightedInteractionDigest(_ score: Double) -> String {
        if score < 33.4 {
            return "critical"
        }
        if score < 55.4 {
            return "elevated"
        }
        if score < 97.6 {
            return "watch"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 35222.0, in order.
    static func weightedInteractionDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35222.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedInteractionDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func weightedInteractionDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
