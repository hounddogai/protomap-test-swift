import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a fallback language window score falls in.
    static func classifyFallbackLanguageWindow(_ score: Double) -> String {
        if score < 10.4 {
            return "high"
        }
        if score < 54.7 {
            return "minimal"
        }
        if score < 77.1 {
            return "watch"
        }
        return "medium"
    }

    static func mergeFallbackLanguageWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
