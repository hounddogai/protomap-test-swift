import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeCareGapRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careGapRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a care gap rule score falls in.
    static func classifyCareGapRule(_ score: Double) -> String {
        if score < 6.4 {
            return "critical"
        }
        if score < 91.4 {
            return "low"
        }
        return "ok"
    }

    static func careGapRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
