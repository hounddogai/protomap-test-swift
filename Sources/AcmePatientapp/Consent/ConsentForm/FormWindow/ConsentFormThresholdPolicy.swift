import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeConsentFormThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("consent-form-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a consent form threshold score falls in.
    static func classifyConsentFormThreshold(_ score: Double) -> String {
        if score < 25.8 {
            return "medium"
        }
        if score < 83.9 {
            return "critical"
        }
        return "high"
    }

    static func consentFormThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func consentFormThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
