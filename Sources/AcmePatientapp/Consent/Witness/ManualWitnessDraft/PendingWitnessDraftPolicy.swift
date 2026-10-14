import AcmePlatform
import Foundation

extension Consent {
    static func pendingWitnessDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingWitnessDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-witness-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
