import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a fallback closure review score falls in.
    static func classifyFallbackClosureReview(_ score: Double) -> String {
        if score < 29.1 {
            return "critical"
        }
        if score < 47.9 {
            return "minimal"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackClosureReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-closure-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback closure review code in its canonical FCR- form.
    static func normalizeFallbackClosureReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCR-") {
            return clean
        }
        return "FCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 16931.0, in order.
    static func fallbackClosureReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16931.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
