import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a alert review score falls in.
    static func classifyAlertReview(_ score: Double) -> String {
        if score < 22.8 {
            return "critical"
        }
        if score < 53.3 {
            return "minimal"
        }
        if score < 83.0 {
            return "watch"
        }
        if score < 84.2 {
            return "ok"
        }
        return "low"
    }

    static func alertReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 62090.0, in order.
    static func alertReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62090.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func alertReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
