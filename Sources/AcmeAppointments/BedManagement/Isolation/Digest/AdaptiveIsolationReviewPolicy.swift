import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeAdaptiveIsolationReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveIsolationReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-isolation-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive isolation review score falls in.
    static func classifyAdaptiveIsolationReview(_ score: Double) -> String {
        if score < 31.4 {
            return "low"
        }
        if score < 36.3 {
            return "watch"
        }
        if score < 79.8 {
            return "elevated"
        }
        if score < 86.8 {
            return "ok"
        }
        return "high"
    }
}
