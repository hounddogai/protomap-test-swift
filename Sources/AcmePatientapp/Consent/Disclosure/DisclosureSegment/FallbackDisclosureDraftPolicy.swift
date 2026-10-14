import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackDisclosureDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-disclosure-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 43669.0, in order.
    static func fallbackDisclosureDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43669.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
