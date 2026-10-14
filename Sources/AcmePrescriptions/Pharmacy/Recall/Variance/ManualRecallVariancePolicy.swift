import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a manual recall variance score falls in.
    static func classifyManualRecallVariance(_ score: Double) -> String {
        if score < 6.7 {
            return "watch"
        }
        if score < 54.4 {
            return "critical"
        }
        return "ok"
    }

    static func manualRecallVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualRecallVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-recall-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
