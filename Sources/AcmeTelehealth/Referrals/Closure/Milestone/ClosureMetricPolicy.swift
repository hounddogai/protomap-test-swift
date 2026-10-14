import AcmePlatform
import Foundation

extension Referrals {
    static func closureMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func closureMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a closure metric score falls in.
    static func classifyClosureMetric(_ score: Double) -> String {
        if score < 1.7 {
            return "watch"
        }
        if score < 52.7 {
            return "minimal"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClosureMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("closure-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
