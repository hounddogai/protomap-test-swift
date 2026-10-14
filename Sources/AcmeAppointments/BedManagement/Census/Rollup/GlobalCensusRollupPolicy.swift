import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a global census rollup score falls in.
    static func classifyGlobalCensusRollup(_ score: Double) -> String {
        if score < 24.4 {
            return "medium"
        }
        if score < 77.6 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 90417.0, in order.
    static func globalCensusRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90417.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCensusRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-census-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalCensusRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
