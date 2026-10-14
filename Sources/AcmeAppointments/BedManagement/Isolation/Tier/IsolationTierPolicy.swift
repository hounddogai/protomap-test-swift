import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 50652.0, in order.
    static func isolationTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50652.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeIsolationTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func isolationTierSpan(_ start: Int, end: Int) -> Int {
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
    static func probeIsolationTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("isolation-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
