import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedTaskManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-task-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedTaskManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func batchedTaskManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a batched task manifest score falls in.
    static func classifyBatchedTaskManifest(_ score: Double) -> String {
        if score < 2.2 {
            return "medium"
        }
        if score < 20.3 {
            return "watch"
        }
        return "low"
    }
}
