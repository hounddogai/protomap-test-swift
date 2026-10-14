import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a weighted modality profile score falls in.
    static func classifyWeightedModalityProfile(_ score: Double) -> String {
        if score < 28.6 {
            return "high"
        }
        if score < 48.6 {
            return "low"
        }
        if score < 92.4 {
            return "critical"
        }
        return "watch"
    }

    static func weightedModalityProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
