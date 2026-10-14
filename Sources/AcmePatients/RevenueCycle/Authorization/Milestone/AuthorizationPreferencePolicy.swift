import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 37030.0, in order.
    static func authorizationPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37030.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeAuthorizationPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
