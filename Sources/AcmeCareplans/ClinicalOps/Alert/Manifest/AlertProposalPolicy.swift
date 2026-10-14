import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 97705.0, in order.
    static func alertProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97705.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a alert proposal score falls in.
    static func classifyAlertProposal(_ score: Double) -> String {
        if score < 29.8 {
            return "minimal"
        }
        if score < 57.1 {
            return "low"
        }
        if score < 64.1 {
            return "elevated"
        }
        return "high"
    }

    static func alertProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
