import AcmePlatform
import Foundation

extension Referrals {
    static func networkCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 47495.0, in order.
    static func networkCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47495.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func networkCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
