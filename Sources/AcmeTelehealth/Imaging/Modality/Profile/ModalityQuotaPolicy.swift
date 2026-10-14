import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a modality quota score falls in.
    static func classifyModalityQuota(_ score: Double) -> String {
        if score < 28.5 {
            return "watch"
        }
        if score < 96.2 {
            return "critical"
        }
        if score < 99.9 {
            return "low"
        }
        return "ok"
    }

    static func modalityQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
