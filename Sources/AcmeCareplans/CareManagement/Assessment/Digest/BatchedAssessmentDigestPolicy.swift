import AcmePlatform
import Foundation

extension CareManagement {
    static func batchedAssessmentDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a batched assessment digest score falls in.
    static func classifyBatchedAssessmentDigest(_ score: Double) -> String {
        if score < 15.2 {
            return "critical"
        }
        if score < 46.2 {
            return "watch"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAssessmentDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-assessment-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
