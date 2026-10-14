import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careGapEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a care gap estimate score falls in.
    static func classifyCareGapEstimate(_ score: Double) -> String {
        if score < 19.6 {
            return "ok"
        }
        if score < 26.6 {
            return "critical"
        }
        if score < 62.2 {
            return "minimal"
        }
        return "high"
    }
}
