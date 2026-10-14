import AcmePlatform
import Foundation

extension Consent {
    static func seasonalConsentFormTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a seasonal consent form target score falls in.
    static func classifySeasonalConsentFormTarget(_ score: Double) -> String {
        if score < 6.5 {
            return "low"
        }
        if score < 68.2 {
            return "ok"
        }
        if score < 75.5 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalConsentFormTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-consent-form-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalConsentFormTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
