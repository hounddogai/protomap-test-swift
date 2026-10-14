import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a fallback authorization audit score falls in.
    static func classifyFallbackAuthorizationAudit(_ score: Double) -> String {
        if score < 47.9 {
            return "critical"
        }
        if score < 76.4 {
            return "watch"
        }
        if score < 77.5 {
            return "low"
        }
        if score < 78.1 {
            return "high"
        }
        return "elevated"
    }

    static func fallbackAuthorizationAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeFallbackAuthorizationAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
