import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackConsentFormPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-consent-form-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback consent form policy score falls in.
    static func classifyFallbackConsentFormPolicy(_ score: Double) -> String {
        if score < 59.8 {
            return "critical"
        }
        if score < 68.1 {
            return "low"
        }
        if score < 93.8 {
            return "ok"
        }
        if score < 97.7 {
            return "medium"
        }
        return "high"
    }

    static func fallbackConsentFormPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 9399.0, in order.
    static func fallbackConsentFormPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9399.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
