import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 11756.0, in order.
    static func regionalDispenseRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11756.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalDispenseRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func regionalDispenseRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
