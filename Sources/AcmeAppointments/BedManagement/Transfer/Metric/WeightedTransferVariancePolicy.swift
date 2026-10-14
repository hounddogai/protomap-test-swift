import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 97814.0, in order.
    static func weightedTransferVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97814.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedTransferVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func weightedTransferVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
