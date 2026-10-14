import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a fallback remittance target score falls in.
    static func classifyFallbackRemittanceTarget(_ score: Double) -> String {
        if score < 7.4 {
            return "ok"
        }
        if score < 16.7 {
            return "minimal"
        }
        if score < 39.4 {
            return "low"
        }
        if score < 97.7 {
            return "watch"
        }
        return "elevated"
    }

    static func fallbackRemittanceTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeFallbackRemittanceTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
