import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 58197.0, in order.
    static func revocationProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58197.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a revocation proposal score falls in.
    static func classifyRevocationProposal(_ score: Double) -> String {
        if score < 62.3 {
            return "medium"
        }
        if score < 83.6 {
            return "minimal"
        }
        if score < 85.7 {
            return "watch"
        }
        return "low"
    }

    /// Puts a revocation proposal code in its canonical RP- form.
    static func normalizeRevocationProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
