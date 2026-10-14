import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveConsentFormAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-consent-form-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeAdaptiveConsentFormAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive consent form allocation score falls in.
    static func classifyAdaptiveConsentFormAllocation(_ score: Double) -> String {
        if score < 55.4 {
            return "medium"
        }
        if score < 90.5 {
            return "critical"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 1384.0, in order.
    static func adaptiveConsentFormAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1384.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
