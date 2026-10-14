import AcmePlatform
import Foundation

extension Consent {
    static func consentFormMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a consent form metric score falls in.
    static func classifyConsentFormMetric(_ score: Double) -> String {
        if score < 8.0 {
            return "critical"
        }
        if score < 23.1 {
            return "watch"
        }
        if score < 29.2 {
            return "high"
        }
        return "minimal"
    }

    static func consentFormMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func consentFormMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
