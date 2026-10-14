import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredFollowUpMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-follow-up-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered follow up metric score falls in.
    static func classifyTieredFollowUpMetric(_ score: Double) -> String {
        if score < 8.3 {
            return "medium"
        }
        if score < 36.1 {
            return "ok"
        }
        if score < 37.4 {
            return "high"
        }
        if score < 41.8 {
            return "elevated"
        }
        return "minimal"
    }
}
