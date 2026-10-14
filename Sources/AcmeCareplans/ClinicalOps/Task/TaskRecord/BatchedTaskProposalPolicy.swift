import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 12904.0, in order.
    static func batchedTaskProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12904.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedTaskProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched task proposal score falls in.
    static func classifyBatchedTaskProposal(_ score: Double) -> String {
        if score < 7.9 {
            return "watch"
        }
        if score < 69.9 {
            return "medium"
        }
        return "low"
    }

    static func batchedTaskProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
