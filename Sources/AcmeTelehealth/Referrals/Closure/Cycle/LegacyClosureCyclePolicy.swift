import AcmePlatform
import Foundation

extension Referrals {
    static func legacyClosureCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a legacy closure cycle score falls in.
    static func classifyLegacyClosureCycle(_ score: Double) -> String {
        if score < 10.8 {
            return "low"
        }
        if score < 28.3 {
            return "critical"
        }
        return "watch"
    }

    static func mergeLegacyClosureCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func legacyClosureCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
