import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 46536.0, in order.
    static func tieredReferralMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46536.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredReferralMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func tieredReferralMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func tieredReferralMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.5
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
