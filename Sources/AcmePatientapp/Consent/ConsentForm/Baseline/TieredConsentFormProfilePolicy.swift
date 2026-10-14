import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 8924.0, in order.
    static func tieredConsentFormProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8924.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredConsentFormProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-consent-form-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredConsentFormProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
