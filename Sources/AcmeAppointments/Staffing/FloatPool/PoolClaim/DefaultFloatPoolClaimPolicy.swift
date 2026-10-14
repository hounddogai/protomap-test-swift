import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a default float pool claim score falls in.
    static func classifyDefaultFloatPoolClaim(_ score: Double) -> String {
        if score < 20.6 {
            return "ok"
        }
        if score < 37.2 {
            return "low"
        }
        if score < 90.1 {
            return "critical"
        }
        return "high"
    }

    static func defaultFloatPoolClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeDefaultFloatPoolClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
