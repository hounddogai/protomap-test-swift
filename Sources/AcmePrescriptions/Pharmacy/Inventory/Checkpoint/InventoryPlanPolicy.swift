import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInventoryPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("inventory-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 93979.0, in order.
    static func inventoryPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93979.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a inventory plan score falls in.
    static func classifyInventoryPlan(_ score: Double) -> String {
        if score < 9.3 {
            return "elevated"
        }
        if score < 11.9 {
            return "watch"
        }
        if score < 90.0 {
            return "high"
        }
        return "critical"
    }

    static func inventoryPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
