import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 62744.0, in order.
    static func censusBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62744.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func censusBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func censusBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
