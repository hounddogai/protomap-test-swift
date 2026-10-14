import AcmePlatform
import Foundation

extension Pharmacy {
    static func batchedInventoryPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 40613.0, in order.
    static func batchedInventoryPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40613.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched inventory policy score falls in.
    static func classifyBatchedInventoryPolicy(_ score: Double) -> String {
        if score < 72.8 {
            return "ok"
        }
        if score < 86.5 {
            return "watch"
        }
        if score < 91.4 {
            return "critical"
        }
        return "minimal"
    }

    static func mergeBatchedInventoryPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
