import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientFollowUpTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-follow-up-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient follow up target score falls in.
    static func classifyLenientFollowUpTarget(_ score: Double) -> String {
        if score < 44.4 {
            return "high"
        }
        if score < 51.8 {
            return "watch"
        }
        return "low"
    }

    static func lenientFollowUpTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
