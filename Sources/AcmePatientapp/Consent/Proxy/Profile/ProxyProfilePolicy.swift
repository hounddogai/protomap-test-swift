import AcmePlatform
import Foundation

extension Consent {
    static func proxyProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func mergeProxyProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a proxy profile score falls in.
    static func classifyProxyProfile(_ score: Double) -> String {
        if score < 71.5 {
            return "low"
        }
        if score < 72.4 {
            return "critical"
        }
        return "watch"
    }
}
