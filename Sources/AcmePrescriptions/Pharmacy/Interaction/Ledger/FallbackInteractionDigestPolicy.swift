import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackInteractionDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackInteractionDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-interaction-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
