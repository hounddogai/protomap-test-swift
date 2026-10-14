import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientFollowUpMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-follow-up-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient follow up mapping score falls in.
    static func classifyLenientFollowUpMapping(_ score: Double) -> String {
        if score < 30.7 {
            return "high"
        }
        if score < 32.5 {
            return "critical"
        }
        if score < 72.6 {
            return "minimal"
        }
        if score < 79.9 {
            return "watch"
        }
        return "low"
    }
}
