import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial estimate score falls in.
    static func classifyDenialEstimate(_ score: Double) -> String {
        if score < 33.2 {
            return "critical"
        }
        if score < 50.3 {
            return "medium"
        }
        if score < 51.0 {
            return "watch"
        }
        if score < 82.8 {
            return "elevated"
        }
        return "low"
    }

    static func denialEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func denialEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 90335.0, in order.
    static func denialEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90335.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
