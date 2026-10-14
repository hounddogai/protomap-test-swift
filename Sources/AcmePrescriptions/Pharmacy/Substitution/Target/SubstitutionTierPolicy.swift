import AcmePlatform
import Foundation

extension Pharmacy {
    static func substitutionTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func substitutionTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a substitution tier score falls in.
    static func classifySubstitutionTier(_ score: Double) -> String {
        if score < 6.0 {
            return "elevated"
        }
        if score < 23.9 {
            return "critical"
        }
        if score < 43.9 {
            return "high"
        }
        return "low"
    }
}
