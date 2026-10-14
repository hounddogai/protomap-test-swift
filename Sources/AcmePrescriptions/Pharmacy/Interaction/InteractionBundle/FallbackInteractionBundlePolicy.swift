import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackInteractionBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeFallbackInteractionBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a fallback interaction bundle score falls in.
    static func classifyFallbackInteractionBundle(_ score: Double) -> String {
        if score < 7.6 {
            return "critical"
        }
        if score < 62.2 {
            return "elevated"
        }
        return "medium"
    }
}
