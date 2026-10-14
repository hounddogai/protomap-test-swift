import AcmePlatform
import Foundation

extension ClinicalOps {
    static func orderSetMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func orderSetMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a order set metric score falls in.
    static func classifyOrderSetMetric(_ score: Double) -> String {
        if score < 37.3 {
            return "high"
        }
        if score < 46.9 {
            return "watch"
        }
        if score < 81.9 {
            return "critical"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
