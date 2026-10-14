import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a tiered float pool plan score falls in.
    static func classifyTieredFloatPoolPlan(_ score: Double) -> String {
        if score < 28.4 {
            return "elevated"
        }
        if score < 34.2 {
            return "high"
        }
        if score < 97.2 {
            return "watch"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredFloatPoolPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-float-pool-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
