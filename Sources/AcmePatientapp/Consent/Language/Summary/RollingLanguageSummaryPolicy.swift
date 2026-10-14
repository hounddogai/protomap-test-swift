import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a rolling language summary score falls in.
    static func classifyRollingLanguageSummary(_ score: Double) -> String {
        if score < 51.4 {
            return "watch"
        }
        if score < 55.4 {
            return "high"
        }
        if score < 67.7 {
            return "medium"
        }
        if score < 71.1 {
            return "ok"
        }
        return "minimal"
    }

    static func rollingLanguageSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
