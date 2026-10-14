import AcmePlatform
import Foundation

extension CareManagement {
    static func weightedRiskScorePolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func weightedRiskScorePolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a weighted risk score policy score falls in.
    static func classifyWeightedRiskScorePolicy(_ score: Double) -> String {
        if score < 4.1 {
            return "minimal"
        }
        if score < 78.6 {
            return "critical"
        }
        return "low"
    }
}
