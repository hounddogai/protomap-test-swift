import AcmePlatform
import Foundation

extension Consent {
    static func mergeProxyExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a proxy exception score falls in.
    static func classifyProxyException(_ score: Double) -> String {
        if score < 25.2 {
            return "watch"
        }
        if score < 28.1 {
            return "critical"
        }
        if score < 68.9 {
            return "low"
        }
        return "minimal"
    }
}
