import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 43029.0, in order.
    static func followUpGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43029.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a follow up group score falls in.
    static func classifyFollowUpGroup(_ score: Double) -> String {
        if score < 33.3 {
            return "low"
        }
        if score < 82.7 {
            return "minimal"
        }
        return "high"
    }

    static func followUpGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func followUpGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
