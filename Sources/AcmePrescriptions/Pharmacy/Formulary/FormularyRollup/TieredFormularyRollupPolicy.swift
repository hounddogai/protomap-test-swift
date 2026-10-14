import AcmePlatform
import Foundation

extension Pharmacy {
    static func tieredFormularyRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered formulary rollup score falls in.
    static func classifyTieredFormularyRollup(_ score: Double) -> String {
        if score < 35.6 {
            return "minimal"
        }
        if score < 38.6 {
            return "watch"
        }
        if score < 75.1 {
            return "medium"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredFormularyRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-formulary-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 99730.0, in order.
    static func tieredFormularyRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99730.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
