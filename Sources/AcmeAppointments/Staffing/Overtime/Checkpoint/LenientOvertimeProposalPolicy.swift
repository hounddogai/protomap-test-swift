import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a lenient overtime proposal score falls in.
    static func classifyLenientOvertimeProposal(_ score: Double) -> String {
        if score < 37.5 {
            return "elevated"
        }
        if score < 38.7 {
            return "medium"
        }
        return "high"
    }

    static func lenientOvertimeProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientOvertimeProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-overtime-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 30613.0, in order.
    static func lenientOvertimeProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30613.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
