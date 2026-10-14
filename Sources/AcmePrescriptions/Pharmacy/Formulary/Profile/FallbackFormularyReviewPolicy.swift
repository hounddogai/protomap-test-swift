import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackFormularyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a fallback formulary review score falls in.
    static func classifyFallbackFormularyReview(_ score: Double) -> String {
        if score < 17.5 {
            return "high"
        }
        if score < 30.2 {
            return "watch"
        }
        if score < 86.5 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 5816.0, in order.
    static func fallbackFormularyReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5816.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackFormularyReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
