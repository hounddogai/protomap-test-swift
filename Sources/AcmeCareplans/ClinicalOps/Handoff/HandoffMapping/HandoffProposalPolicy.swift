import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 36606.0, in order.
    static func handoffProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36606.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a handoff proposal score falls in.
    static func classifyHandoffProposal(_ score: Double) -> String {
        if score < 54.9 {
            return "ok"
        }
        if score < 69.5 {
            return "critical"
        }
        if score < 73.4 {
            return "high"
        }
        return "medium"
    }

    /// Puts a handoff proposal code in its canonical HP- form.
    static func normalizeHandoffProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HP-") {
            return clean
        }
        return "HP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
