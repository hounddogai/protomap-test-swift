import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 70962.0, in order.
    static func claimAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70962.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a claim agreement code in its canonical CA- form.
    static func normalizeClaimAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
