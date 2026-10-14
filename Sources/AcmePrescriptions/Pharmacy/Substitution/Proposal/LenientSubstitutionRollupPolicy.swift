import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeLenientSubstitutionRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 92413.0, in order.
    static func lenientSubstitutionRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92413.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientSubstitutionRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientSubstitutionRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-substitution-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
