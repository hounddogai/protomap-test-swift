import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a charge metric score falls in.
    static func classifyChargeMetric(_ score: Double) -> String {
        if score < 62.9 {
            return "high"
        }
        if score < 82.1 {
            return "ok"
        }
        if score < 89.8 {
            return "medium"
        }
        if score < 99.0 {
            return "low"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeChargeMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("charge-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
