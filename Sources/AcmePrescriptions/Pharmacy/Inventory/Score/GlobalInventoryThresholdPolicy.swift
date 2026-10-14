import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a global inventory threshold score falls in.
    static func classifyGlobalInventoryThreshold(_ score: Double) -> String {
        if score < 34.9 {
            return "ok"
        }
        if score < 78.3 {
            return "elevated"
        }
        if score < 80.4 {
            return "low"
        }
        if score < 94.4 {
            return "critical"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalInventoryThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-inventory-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalInventoryThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 13600.0, in order.
    static func globalInventoryThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13600.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
