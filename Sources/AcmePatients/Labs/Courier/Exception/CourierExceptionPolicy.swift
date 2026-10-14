import AcmePlatform
import Foundation

extension Labs {
    static func courierExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCourierException() -> Int {
        let policy = Kit.Retry.defaultPolicy("courier-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a courier exception score falls in.
    static func classifyCourierException(_ score: Double) -> String {
        if score < 15.6 {
            return "elevated"
        }
        if score < 70.1 {
            return "critical"
        }
        if score < 82.6 {
            return "ok"
        }
        return "high"
    }
}
