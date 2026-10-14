import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredClosureMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-closure-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredClosureMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
