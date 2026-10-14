import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualFormularyReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual formulary review score falls in.
    static func classifyManualFormularyReview(_ score: Double) -> String {
        if score < 54.6 {
            return "medium"
        }
        if score < 78.1 {
            return "low"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualFormularyReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-formulary-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 19658.0, in order.
    static func manualFormularyReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19658.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
