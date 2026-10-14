import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a batched remittance allocation score falls in.
    static func classifyBatchedRemittanceAllocation(_ score: Double) -> String {
        if score < 58.0 {
            return "critical"
        }
        if score < 71.9 {
            return "low"
        }
        if score < 78.7 {
            return "elevated"
        }
        return "watch"
    }

    /// Puts a batched remittance allocation code in its canonical BRA- form.
    static func normalizeBatchedRemittanceAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRA-") {
            return clean
        }
        return "BRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedRemittanceAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 47123.0, in order.
    static func batchedRemittanceAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47123.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
