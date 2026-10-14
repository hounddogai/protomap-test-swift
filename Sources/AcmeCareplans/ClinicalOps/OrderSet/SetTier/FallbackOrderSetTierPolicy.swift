import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a fallback order set tier score falls in.
    static func classifyFallbackOrderSetTier(_ score: Double) -> String {
        if score < 27.0 {
            return "watch"
        }
        if score < 34.5 {
            return "minimal"
        }
        if score < 50.7 {
            return "ok"
        }
        if score < 57.9 {
            return "elevated"
        }
        return "low"
    }

    static func fallbackOrderSetTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
