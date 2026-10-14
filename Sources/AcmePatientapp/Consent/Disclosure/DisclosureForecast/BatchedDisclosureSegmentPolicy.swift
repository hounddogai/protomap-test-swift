import AcmePlatform
import Foundation

extension Consent {
    static func batchedDisclosureSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched disclosure segment score falls in.
    static func classifyBatchedDisclosureSegment(_ score: Double) -> String {
        if score < 36.1 {
            return "minimal"
        }
        if score < 39.0 {
            return "ok"
        }
        if score < 85.1 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedDisclosureSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-disclosure-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
