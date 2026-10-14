import AcmePlatform
import Foundation

extension Labs {
    static func weightedAccessionMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a weighted accession mapping score falls in.
    static func classifyWeightedAccessionMapping(_ score: Double) -> String {
        if score < 23.0 {
            return "elevated"
        }
        if score < 46.4 {
            return "high"
        }
        if score < 50.8 {
            return "critical"
        }
        return "watch"
    }
}
