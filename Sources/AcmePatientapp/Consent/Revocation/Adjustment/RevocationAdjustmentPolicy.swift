import AcmePlatform
import Foundation

extension Consent {
    static func revocationAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a revocation adjustment score falls in.
    static func classifyRevocationAdjustment(_ score: Double) -> String {
        if score < 6.7 {
            return "ok"
        }
        if score < 11.3 {
            return "elevated"
        }
        if score < 83.4 {
            return "high"
        }
        if score < 84.0 {
            return "low"
        }
        return "critical"
    }

    static func mergeRevocationAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
