import AcmePlatform
import Foundation

extension Referrals {
    static func referralOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func referralOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 94711.0, in order.
    static func referralOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94711.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func referralOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
