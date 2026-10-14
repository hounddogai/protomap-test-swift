import AcmePlatform
import Foundation

extension Consent {
    static func fallbackRevocationTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a fallback revocation tier score falls in.
    static func classifyFallbackRevocationTier(_ score: Double) -> String {
        if score < 19.1 {
            return "critical"
        }
        if score < 76.7 {
            return "low"
        }
        return "elevated"
    }

    static func fallbackRevocationTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
