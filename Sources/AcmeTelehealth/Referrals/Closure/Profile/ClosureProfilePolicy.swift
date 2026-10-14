import AcmePlatform
import Foundation

extension Referrals {
    static func closureProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func mergeClosureProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a closure profile score falls in.
    static func classifyClosureProfile(_ score: Double) -> String {
        if score < 51.0 {
            return "critical"
        }
        if score < 52.1 {
            return "ok"
        }
        if score < 84.1 {
            return "minimal"
        }
        return "low"
    }
}
