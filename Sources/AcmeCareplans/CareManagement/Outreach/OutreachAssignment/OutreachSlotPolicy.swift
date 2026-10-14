import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 72675.0, in order.
    static func outreachSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72675.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func outreachSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
