import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 98616.0, in order.
    static func batchedProxySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98616.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeBatchedProxySlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedProxySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-proxy-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
