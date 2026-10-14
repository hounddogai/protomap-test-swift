import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form budget score falls in.
    static func classifyConsentFormBudget(_ score: Double) -> String {
        if score < 10.0 {
            return "high"
        }
        if score < 29.3 {
            return "minimal"
        }
        if score < 37.3 {
            return "medium"
        }
        if score < 71.5 {
            return "ok"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeConsentFormBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("consent-form-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 7763.0, in order.
    static func consentFormBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7763.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func consentFormBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
