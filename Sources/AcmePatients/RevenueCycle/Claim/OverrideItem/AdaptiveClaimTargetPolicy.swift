import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveClaimTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-claim-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveClaimTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveClaimTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a adaptive claim target score falls in.
    static func classifyAdaptiveClaimTarget(_ score: Double) -> String {
        if score < 29.7 {
            return "ok"
        }
        if score < 80.1 {
            return "watch"
        }
        return "medium"
    }
}
