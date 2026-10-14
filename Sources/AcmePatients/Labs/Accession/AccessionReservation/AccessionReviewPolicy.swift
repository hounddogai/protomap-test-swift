import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func accessionReviewSpan(_ start: Int, end: Int) -> Int {
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
