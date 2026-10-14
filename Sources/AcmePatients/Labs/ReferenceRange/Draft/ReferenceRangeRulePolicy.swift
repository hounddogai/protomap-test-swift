import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a reference range rule score falls in.
    static func classifyReferenceRangeRule(_ score: Double) -> String {
        if score < 1.4 {
            return "ok"
        }
        if score < 56.0 {
            return "low"
        }
        if score < 68.6 {
            return "medium"
        }
        return "minimal"
    }

    static func mergeReferenceRangeRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
