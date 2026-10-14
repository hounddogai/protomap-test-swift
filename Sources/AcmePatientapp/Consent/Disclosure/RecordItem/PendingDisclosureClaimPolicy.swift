import AcmePlatform
import Foundation

extension Consent {
    static func pendingDisclosureClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a pending disclosure claim score falls in.
    static func classifyPendingDisclosureClaim(_ score: Double) -> String {
        if score < 4.8 {
            return "elevated"
        }
        if score < 44.5 {
            return "high"
        }
        if score < 54.3 {
            return "watch"
        }
        if score < 81.6 {
            return "minimal"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingDisclosureClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-disclosure-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
