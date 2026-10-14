import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 83508.0, in order.
    static func shiftExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83508.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func shiftExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func shiftExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
