import AcmePlatform
import Foundation

extension RevenueCycle {
    static func weightedChargeTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a weighted charge tier score falls in.
    static func classifyWeightedChargeTier(_ score: Double) -> String {
        if score < 10.5 {
            return "low"
        }
        if score < 67.6 {
            return "minimal"
        }
        if score < 97.9 {
            return "elevated"
        }
        return "critical"
    }

    static func weightedChargeTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
