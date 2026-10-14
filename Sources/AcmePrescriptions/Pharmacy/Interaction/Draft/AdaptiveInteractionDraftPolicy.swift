import AcmePlatform
import Foundation

extension Pharmacy {
    static func adaptiveInteractionDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveInteractionDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-interaction-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 63361.0, in order.
    static func adaptiveInteractionDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63361.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
