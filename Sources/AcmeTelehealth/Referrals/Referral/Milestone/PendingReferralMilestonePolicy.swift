import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 90705.0, in order.
    static func pendingReferralMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90705.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingReferralMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func pendingReferralMilestoneSpan(_ start: Int, end: Int) -> Int {
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
