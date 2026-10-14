import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a weighted care gap claim score falls in.
    static func classifyWeightedCareGapClaim(_ score: Double) -> String {
        if score < 8.5 {
            return "low"
        }
        if score < 93.7 {
            return "high"
        }
        return "minimal"
    }

    static func weightedCareGapClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func weightedCareGapClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
