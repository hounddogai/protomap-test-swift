import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualOvertimeProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-overtime-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 71317.0, in order.
    static func manualOvertimeProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71317.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualOvertimeProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a manual overtime proposal score falls in.
    static func classifyManualOvertimeProposal(_ score: Double) -> String {
        if score < 21.0 {
            return "ok"
        }
        if score < 74.6 {
            return "medium"
        }
        return "critical"
    }
}
