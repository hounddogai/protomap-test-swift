import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 44244.0, in order.
    static func isolationProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44244.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeIsolationProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("isolation-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func isolationProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a isolation proposal code in its canonical IP- form.
    static func normalizeIsolationProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IP-") {
            return clean
        }
        return "IP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
