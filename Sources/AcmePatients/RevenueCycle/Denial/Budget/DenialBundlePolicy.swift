import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func denialBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 60097.0, in order.
    static func denialBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60097.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
