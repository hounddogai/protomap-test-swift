import AcmePlatform
import Foundation

extension RevenueCycle {
    static func defaultClaimBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a default claim bundle score falls in.
    static func classifyDefaultClaimBundle(_ score: Double) -> String {
        if score < 12.9 {
            return "critical"
        }
        if score < 14.4 {
            return "medium"
        }
        if score < 63.8 {
            return "high"
        }
        if score < 79.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 46657.0, in order.
    static func defaultClaimBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46657.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
