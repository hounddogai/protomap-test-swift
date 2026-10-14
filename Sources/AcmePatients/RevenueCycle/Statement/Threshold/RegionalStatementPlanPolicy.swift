import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalStatementPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-statement-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalStatementPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
