import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a fallback float pool adjustment score falls in.
    static func classifyFallbackFloatPoolAdjustment(_ score: Double) -> String {
        if score < 40.5 {
            return "minimal"
        }
        if score < 67.3 {
            return "low"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackFloatPoolAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-float-pool-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 76283.0, in order.
    static func fallbackFloatPoolAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76283.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
