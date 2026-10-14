import AcmePlatform
import Foundation

extension Consent {
    static func pendingConsentFormCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func pendingConsentFormCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a pending consent form checkpoint score falls in.
    static func classifyPendingConsentFormCheckpoint(_ score: Double) -> String {
        if score < 19.0 {
            return "elevated"
        }
        if score < 34.1 {
            return "critical"
        }
        if score < 82.3 {
            return "watch"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingConsentFormCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-consent-form-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
