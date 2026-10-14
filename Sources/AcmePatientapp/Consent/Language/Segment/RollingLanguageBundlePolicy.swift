import AcmePlatform
import Foundation

extension Consent {
    static func rollingLanguageBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a rolling language bundle score falls in.
    static func classifyRollingLanguageBundle(_ score: Double) -> String {
        if score < 32.5 {
            return "elevated"
        }
        if score < 38.3 {
            return "low"
        }
        if score < 56.3 {
            return "critical"
        }
        return "medium"
    }
}
