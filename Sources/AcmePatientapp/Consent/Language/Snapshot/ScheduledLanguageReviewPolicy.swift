import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledLanguageReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-language-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled language review score falls in.
    static func classifyScheduledLanguageReview(_ score: Double) -> String {
        if score < 32.6 {
            return "medium"
        }
        if score < 34.2 {
            return "minimal"
        }
        if score < 78.1 {
            return "high"
        }
        if score < 78.3 {
            return "ok"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 77800.0, in order.
    static func scheduledLanguageReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77800.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
