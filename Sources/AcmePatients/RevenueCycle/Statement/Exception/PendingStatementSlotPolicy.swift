import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergePendingStatementSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending statement slot score falls in.
    static func classifyPendingStatementSlot(_ score: Double) -> String {
        if score < 42.6 {
            return "elevated"
        }
        if score < 72.0 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 57839.0, in order.
    static func pendingStatementSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57839.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
