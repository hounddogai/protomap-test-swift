import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryCredentialProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-credential-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary credential proposal score falls in.
    static func classifyPrimaryCredentialProposal(_ score: Double) -> String {
        if score < 23.4 {
            return "minimal"
        }
        if score < 26.0 {
            return "low"
        }
        if score < 47.2 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 22178.0, in order.
    static func primaryCredentialProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22178.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryCredentialProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
