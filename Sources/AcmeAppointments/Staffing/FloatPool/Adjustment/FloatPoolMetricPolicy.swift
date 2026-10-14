import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a float pool metric score falls in.
    static func classifyFloatPoolMetric(_ score: Double) -> String {
        if score < 42.0 {
            return "minimal"
        }
        if score < 55.6 {
            return "low"
        }
        if score < 73.7 {
            return "critical"
        }
        if score < 98.6 {
            return "ok"
        }
        return "high"
    }
}
