import AcmePlatform
import Foundation

extension Consent {
    static func lenientProxySummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func lenientProxySummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeLenientProxySummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient proxy summary score falls in.
    static func classifyLenientProxySummary(_ score: Double) -> String {
        if score < 68.6 {
            return "critical"
        }
        if score < 72.8 {
            return "high"
        }
        return "ok"
    }
}
