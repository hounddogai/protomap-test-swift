import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 64472.0, in order.
    static func statementSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64472.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStatementSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a statement slot score falls in.
    static func classifyStatementSlot(_ score: Double) -> String {
        if score < 22.8 {
            return "elevated"
        }
        if score < 42.2 {
            return "watch"
        }
        if score < 59.5 {
            return "critical"
        }
        if score < 89.6 {
            return "ok"
        }
        return "medium"
    }
}
