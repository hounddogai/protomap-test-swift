import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a claim proposal code in its canonical CP- form.
    static func normalizeClaimProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func claimProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
