import AcmePlatform
import Foundation

extension Referrals {
    static func adaptiveNetworkCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a adaptive network cycle score falls in.
    static func classifyAdaptiveNetworkCycle(_ score: Double) -> String {
        if score < 3.7 {
            return "watch"
        }
        if score < 15.1 {
            return "medium"
        }
        if score < 41.7 {
            return "elevated"
        }
        if score < 93.7 {
            return "low"
        }
        return "high"
    }

    static func adaptiveNetworkCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
