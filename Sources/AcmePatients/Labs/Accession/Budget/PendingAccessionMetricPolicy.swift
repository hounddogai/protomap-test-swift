import AcmePlatform
import Foundation

extension Labs {
    static func pendingAccessionMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func pendingAccessionMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending accession metric score falls in.
    static func classifyPendingAccessionMetric(_ score: Double) -> String {
        if score < 59.5 {
            return "watch"
        }
        if score < 65.9 {
            return "low"
        }
        if score < 85.1 {
            return "elevated"
        }
        if score < 87.0 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingAccessionMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-accession-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
