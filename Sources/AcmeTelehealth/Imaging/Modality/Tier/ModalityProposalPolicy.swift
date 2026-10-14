import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 7775.0, in order.
    static func modalityProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7775.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a modality proposal code in its canonical MP- form.
    static func normalizeModalityProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MP-") {
            return clean
        }
        return "MP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
