import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveWitnessDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveWitnessDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a adaptive witness digest score falls in.
    static func classifyAdaptiveWitnessDigest(_ score: Double) -> String {
        if score < 2.1 {
            return "ok"
        }
        if score < 38.6 {
            return "elevated"
        }
        if score < 96.2 {
            return "high"
        }
        return "critical"
    }
}
