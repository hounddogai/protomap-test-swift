import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a scheduled witness proposal score falls in.
    static func classifyScheduledWitnessProposal(_ score: Double) -> String {
        if score < 28.3 {
            return "medium"
        }
        if score < 95.5 {
            return "ok"
        }
        if score < 95.7 {
            return "critical"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 19206.0, in order.
    static func scheduledWitnessProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19206.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledWitnessProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func scheduledWitnessProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
