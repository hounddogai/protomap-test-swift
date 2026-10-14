import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 20598.0, in order.
    static func roundingReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20598.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rounding review score falls in.
    static func classifyRoundingReview(_ score: Double) -> String {
        if score < 55.0 {
            return "watch"
        }
        if score < 60.4 {
            return "elevated"
        }
        if score < 64.5 {
            return "high"
        }
        if score < 94.4 {
            return "medium"
        }
        return "low"
    }

    /// Puts a rounding review code in its canonical RR- form.
    static func normalizeRoundingReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
