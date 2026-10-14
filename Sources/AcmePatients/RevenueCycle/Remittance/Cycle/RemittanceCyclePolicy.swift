import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance cycle score falls in.
    static func classifyRemittanceCycle(_ score: Double) -> String {
        if score < 10.1 {
            return "watch"
        }
        if score < 62.8 {
            return "low"
        }
        if score < 63.4 {
            return "minimal"
        }
        if score < 85.2 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func remittanceCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
