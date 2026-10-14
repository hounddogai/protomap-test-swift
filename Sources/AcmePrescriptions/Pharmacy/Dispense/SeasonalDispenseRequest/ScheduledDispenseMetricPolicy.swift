import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledDispenseMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-dispense-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled dispense metric score falls in.
    static func classifyScheduledDispenseMetric(_ score: Double) -> String {
        if score < 19.4 {
            return "low"
        }
        if score < 71.2 {
            return "high"
        }
        if score < 93.7 {
            return "watch"
        }
        return "ok"
    }

    static func scheduledDispenseMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
