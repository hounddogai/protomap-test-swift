import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a pending handoff plan score falls in.
    static func classifyPendingHandoffPlan(_ score: Double) -> String {
        if score < 25.3 {
            return "minimal"
        }
        if score < 33.3 {
            return "medium"
        }
        if score < 52.4 {
            return "low"
        }
        if score < 75.6 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 33731.0, in order.
    static func pendingHandoffPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33731.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingHandoffPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingHandoffPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-handoff-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
