import AcmePlatform
import Foundation

extension Staffing {
    static func pendingOvertimeMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingOvertimeMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a pending overtime metric score falls in.
    static func classifyPendingOvertimeMetric(_ score: Double) -> String {
        if score < 10.9 {
            return "minimal"
        }
        if score < 41.8 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingOvertimeMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-overtime-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
