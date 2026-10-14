import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictAccessionPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-accession-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictAccessionPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 57347.0, in order.
    static func strictAccessionPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57347.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
