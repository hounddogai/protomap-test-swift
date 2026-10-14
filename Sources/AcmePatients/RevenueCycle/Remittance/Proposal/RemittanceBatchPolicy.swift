import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a remittance batch score falls in.
    static func classifyRemittanceBatch(_ score: Double) -> String {
        if score < 30.7 {
            return "medium"
        }
        if score < 73.7 {
            return "minimal"
        }
        if score < 86.8 {
            return "watch"
        }
        return "elevated"
    }

    static func remittanceBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
