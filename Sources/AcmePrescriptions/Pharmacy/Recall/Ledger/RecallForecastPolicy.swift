import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 47521.0, in order.
    static func recallForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47521.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func recallForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func recallForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
