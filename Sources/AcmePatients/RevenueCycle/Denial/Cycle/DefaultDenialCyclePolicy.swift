import AcmePlatform
import Foundation

extension RevenueCycle {
    static func defaultDenialCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a default denial cycle score falls in.
    static func classifyDefaultDenialCycle(_ score: Double) -> String {
        if score < 14.0 {
            return "critical"
        }
        if score < 17.0 {
            return "high"
        }
        if score < 51.1 {
            return "medium"
        }
        if score < 57.1 {
            return "minimal"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultDenialCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-denial-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
