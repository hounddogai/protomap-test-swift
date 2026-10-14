import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a rolling claim plan score falls in.
    static func classifyRollingClaimPlan(_ score: Double) -> String {
        if score < 18.8 {
            return "high"
        }
        if score < 57.0 {
            return "ok"
        }
        if score < 78.3 {
            return "watch"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingClaimPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-claim-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingClaimPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
