import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 74607.0, in order.
    static func manualConsentFormEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74607.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualConsentFormEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualConsentFormEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-consent-form-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a manual consent form entry score falls in.
    static func classifyManualConsentFormEntry(_ score: Double) -> String {
        if score < 72.0 {
            return "minimal"
        }
        if score < 89.5 {
            return "low"
        }
        return "critical"
    }
}
