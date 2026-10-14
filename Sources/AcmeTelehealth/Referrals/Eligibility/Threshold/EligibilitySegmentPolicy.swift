import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility segment score falls in.
    static func classifyEligibilitySegment(_ score: Double) -> String {
        if score < 41.3 {
            return "low"
        }
        if score < 58.1 {
            return "high"
        }
        if score < 63.9 {
            return "critical"
        }
        return "elevated"
    }

    static func eligibilitySegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 14661.0, in order.
    static func eligibilitySegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14661.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func eligibilitySegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
