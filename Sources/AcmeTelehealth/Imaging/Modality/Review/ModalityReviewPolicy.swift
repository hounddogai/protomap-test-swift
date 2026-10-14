import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a modality review score falls in.
    static func classifyModalityReview(_ score: Double) -> String {
        if score < 50.1 {
            return "elevated"
        }
        if score < 51.8 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 13679.0, in order.
    static func modalityReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13679.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
