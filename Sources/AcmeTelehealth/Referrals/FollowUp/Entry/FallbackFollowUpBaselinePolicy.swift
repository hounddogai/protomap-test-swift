import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a fallback follow up baseline score falls in.
    static func classifyFallbackFollowUpBaseline(_ score: Double) -> String {
        if score < 7.3 {
            return "medium"
        }
        if score < 21.8 {
            return "high"
        }
        if score < 87.7 {
            return "minimal"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackFollowUpBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-follow-up-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
