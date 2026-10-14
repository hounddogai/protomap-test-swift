import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a strict consent form override score falls in.
    static func classifyStrictConsentFormOverride(_ score: Double) -> String {
        if score < 28.5 {
            return "critical"
        }
        if score < 81.7 {
            return "high"
        }
        return "watch"
    }

    static func strictConsentFormOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeStrictConsentFormOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictConsentFormOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
