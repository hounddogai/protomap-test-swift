import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackRecallPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a fallback recall policy score falls in.
    static func classifyFallbackRecallPolicy(_ score: Double) -> String {
        if score < 37.6 {
            return "watch"
        }
        if score < 54.9 {
            return "critical"
        }
        if score < 71.4 {
            return "minimal"
        }
        if score < 82.0 {
            return "medium"
        }
        return "elevated"
    }

    static func mergeFallbackRecallPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
