import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a weighted modality proposal code in its canonical WMP- form.
    static func normalizeWeightedModalityProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WMP-") {
            return clean
        }
        return "WMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a weighted modality proposal score falls in.
    static func classifyWeightedModalityProposal(_ score: Double) -> String {
        if score < 29.3 {
            return "elevated"
        }
        if score < 31.4 {
            return "ok"
        }
        if score < 73.9 {
            return "high"
        }
        if score < 85.0 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedModalityProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-modality-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 66517.0, in order.
    static func weightedModalityProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66517.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
