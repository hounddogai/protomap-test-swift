import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a pending rounding ledger score falls in.
    static func classifyPendingRoundingLedger(_ score: Double) -> String {
        if score < 8.4 {
            return "watch"
        }
        if score < 9.1 {
            return "ok"
        }
        if score < 64.1 {
            return "elevated"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 29687.0, in order.
    static func pendingRoundingLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29687.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingRoundingLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
