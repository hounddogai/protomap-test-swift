import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a strict reference range rule score falls in.
    static func classifyStrictReferenceRangeRule(_ score: Double) -> String {
        if score < 6.0 {
            return "medium"
        }
        if score < 33.5 {
            return "critical"
        }
        return "elevated"
    }

    static func mergeStrictReferenceRangeRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictReferenceRangeRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func strictReferenceRangeRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
