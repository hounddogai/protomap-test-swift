import AcmePlatform
import Foundation

extension Consent {
    static func mergeLanguageExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a language exception score falls in.
    static func classifyLanguageException(_ score: Double) -> String {
        if score < 27.0 {
            return "elevated"
        }
        if score < 53.6 {
            return "critical"
        }
        if score < 94.0 {
            return "low"
        }
        if score < 99.0 {
            return "medium"
        }
        return "high"
    }

    static func languageExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func languageExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
