import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 22173.0, in order.
    static func resultDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22173.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
