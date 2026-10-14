import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a fallback formulary digest score falls in.
    static func classifyFallbackFormularyDigest(_ score: Double) -> String {
        if score < 78.5 {
            return "watch"
        }
        if score < 82.3 {
            return "critical"
        }
        if score < 96.7 {
            return "elevated"
        }
        return "low"
    }

    static func fallbackFormularyDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func fallbackFormularyDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
