import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInventorySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("inventory-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a inventory slot score falls in.
    static func classifyInventorySlot(_ score: Double) -> String {
        if score < 9.0 {
            return "critical"
        }
        if score < 18.4 {
            return "low"
        }
        return "elevated"
    }

    static func inventorySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 49011.0, in order.
    static func inventorySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49011.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
