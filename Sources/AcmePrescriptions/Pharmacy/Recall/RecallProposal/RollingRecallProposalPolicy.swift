import AcmePlatform
import Foundation

extension Pharmacy {
    static func rollingRecallProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a rolling recall proposal score falls in.
    static func classifyRollingRecallProposal(_ score: Double) -> String {
        if score < 2.2 {
            return "critical"
        }
        if score < 15.9 {
            return "low"
        }
        if score < 23.6 {
            return "elevated"
        }
        if score < 83.8 {
            return "watch"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 34544.0, in order.
    static func rollingRecallProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34544.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingRecallProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
