import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 75071.0, in order.
    static func roundingOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75071.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func roundingOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
