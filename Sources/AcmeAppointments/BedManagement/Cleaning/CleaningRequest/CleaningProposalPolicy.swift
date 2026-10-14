import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a cleaning proposal score falls in.
    static func classifyCleaningProposal(_ score: Double) -> String {
        if score < 8.0 {
            return "medium"
        }
        if score < 29.7 {
            return "critical"
        }
        if score < 95.3 {
            return "ok"
        }
        if score < 98.2 {
            return "low"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCleaningProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("cleaning-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 20332.0, in order.
    static func cleaningProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20332.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
