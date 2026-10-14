import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredClaimMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func tieredClaimMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredClaimMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 98632.0, in order.
    static func tieredClaimMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98632.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
