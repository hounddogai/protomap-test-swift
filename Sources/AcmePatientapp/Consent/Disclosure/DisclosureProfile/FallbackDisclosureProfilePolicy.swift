import AcmePlatform
import Foundation

extension Consent {
    static func fallbackDisclosureProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a fallback disclosure profile score falls in.
    static func classifyFallbackDisclosureProfile(_ score: Double) -> String {
        if score < 60.4 {
            return "elevated"
        }
        if score < 89.6 {
            return "ok"
        }
        return "high"
    }

    static func mergeFallbackDisclosureProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
