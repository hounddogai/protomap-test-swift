import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedBedBoardLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a batched bed board ledger score falls in.
    static func classifyBatchedBedBoardLedger(_ score: Double) -> String {
        if score < 36.9 {
            return "minimal"
        }
        if score < 73.3 {
            return "medium"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 45316.0, in order.
    static func batchedBedBoardLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45316.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedBedBoardLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
