import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a strict inventory ledger score falls in.
    static func classifyStrictInventoryLedger(_ score: Double) -> String {
        if score < 41.8 {
            return "ok"
        }
        if score < 93.7 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 90406.0, in order.
    static func strictInventoryLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90406.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStrictInventoryLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
