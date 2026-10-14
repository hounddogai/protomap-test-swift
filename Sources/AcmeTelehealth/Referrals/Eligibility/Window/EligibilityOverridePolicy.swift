import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func eligibilityOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a eligibility override score falls in.
    static func classifyEligibilityOverride(_ score: Double) -> String {
        if score < 16.2 {
            return "low"
        }
        if score < 64.9 {
            return "critical"
        }
        if score < 73.1 {
            return "elevated"
        }
        return "medium"
    }
}
