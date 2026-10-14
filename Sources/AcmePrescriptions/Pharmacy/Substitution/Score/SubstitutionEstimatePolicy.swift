import AcmePlatform
import Foundation

extension Pharmacy {
    static func substitutionEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 76512.0, in order.
    static func substitutionEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76512.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a substitution estimate score falls in.
    static func classifySubstitutionEstimate(_ score: Double) -> String {
        if score < 8.6 {
            return "ok"
        }
        if score < 67.7 {
            return "low"
        }
        if score < 74.7 {
            return "watch"
        }
        if score < 84.6 {
            return "elevated"
        }
        return "minimal"
    }

    static func substitutionEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
