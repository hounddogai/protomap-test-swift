import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCleaningEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-cleaning-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 24418.0, in order.
    static func fallbackCleaningEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24418.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
