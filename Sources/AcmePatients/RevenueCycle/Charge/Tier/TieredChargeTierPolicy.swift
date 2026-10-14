import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a tiered charge tier score falls in.
    static func classifyTieredChargeTier(_ score: Double) -> String {
        if score < 17.8 {
            return "critical"
        }
        if score < 53.9 {
            return "medium"
        }
        if score < 76.0 {
            return "elevated"
        }
        if score < 85.5 {
            return "high"
        }
        return "watch"
    }

    static func tieredChargeTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredChargeTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-charge-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 60300.0, in order.
    static func tieredChargeTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60300.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
