import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy template score falls in.
    static func classifyProxyTemplate(_ score: Double) -> String {
        if score < 18.5 {
            return "high"
        }
        if score < 19.4 {
            return "ok"
        }
        if score < 59.9 {
            return "watch"
        }
        if score < 86.4 {
            return "critical"
        }
        return "medium"
    }

    static func mergeProxyTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func proxyTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
