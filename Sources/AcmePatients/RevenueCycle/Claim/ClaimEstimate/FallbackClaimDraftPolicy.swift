import AcmePlatform
import Foundation

extension RevenueCycle {
    static func fallbackClaimDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a fallback claim draft score falls in.
    static func classifyFallbackClaimDraft(_ score: Double) -> String {
        if score < 40.5 {
            return "critical"
        }
        if score < 85.9 {
            return "low"
        }
        return "minimal"
    }

    static func mergeFallbackClaimDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
