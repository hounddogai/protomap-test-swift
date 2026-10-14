import AcmePlatform
import Foundation

extension Referrals {
    static func primaryFollowUpAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func primaryFollowUpAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
