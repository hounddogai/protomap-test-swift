import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 32035.0, in order.
    static func batchedDisclosurePreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32035.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeBatchedDisclosurePreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedDisclosurePreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-disclosure-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedDisclosurePreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
