import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a adaptive remittance snapshot score falls in.
    static func classifyAdaptiveRemittanceSnapshot(_ score: Double) -> String {
        if score < 43.6 {
            return "watch"
        }
        if score < 75.8 {
            return "low"
        }
        if score < 90.4 {
            return "high"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveRemittanceSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-remittance-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveRemittanceSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
