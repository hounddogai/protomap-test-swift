import AcmePlatform
import Foundation

extension ClinicalOps {
    static func regionalHandoffExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 57506.0, in order.
    static func regionalHandoffExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57506.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalHandoffExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
