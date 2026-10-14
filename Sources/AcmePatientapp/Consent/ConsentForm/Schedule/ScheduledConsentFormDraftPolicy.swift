import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a scheduled consent form draft score falls in.
    static func classifyScheduledConsentFormDraft(_ score: Double) -> String {
        if score < 5.8 {
            return "critical"
        }
        if score < 18.4 {
            return "low"
        }
        if score < 33.9 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledConsentFormDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-consent-form-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
