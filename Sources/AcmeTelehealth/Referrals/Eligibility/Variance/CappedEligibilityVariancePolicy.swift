import AcmePlatform
import Foundation

extension Referrals {
    static func cappedEligibilityVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 50734.0, in order.
    static func cappedEligibilityVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50734.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped eligibility variance score falls in.
    static func classifyCappedEligibilityVariance(_ score: Double) -> String {
        if score < 23.0 {
            return "watch"
        }
        if score < 82.9 {
            return "high"
        }
        return "minimal"
    }
}
