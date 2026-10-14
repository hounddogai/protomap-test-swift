import AcmePlatform
import Foundation

extension Consent {
    static func tieredRevocationRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func mergeTieredRevocationRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered revocation rollup score falls in.
    static func classifyTieredRevocationRollup(_ score: Double) -> String {
        if score < 22.4 {
            return "ok"
        }
        if score < 55.3 {
            return "medium"
        }
        if score < 94.4 {
            return "watch"
        }
        return "minimal"
    }
}
