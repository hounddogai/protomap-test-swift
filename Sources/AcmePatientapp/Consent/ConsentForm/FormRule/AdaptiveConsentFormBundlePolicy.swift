import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a adaptive consent form bundle score falls in.
    static func classifyAdaptiveConsentFormBundle(_ score: Double) -> String {
        if score < 49.3 {
            return "ok"
        }
        if score < 49.8 {
            return "elevated"
        }
        if score < 72.2 {
            return "medium"
        }
        if score < 79.1 {
            return "minimal"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveConsentFormBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-consent-form-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
