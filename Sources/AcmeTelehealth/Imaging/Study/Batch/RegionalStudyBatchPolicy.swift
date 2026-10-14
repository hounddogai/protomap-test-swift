import AcmePlatform
import Foundation

extension Imaging {
    static func regionalStudyBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalStudyBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-study-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
