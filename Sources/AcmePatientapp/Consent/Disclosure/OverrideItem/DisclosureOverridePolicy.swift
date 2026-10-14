import AcmePlatform
import Foundation

extension Consent {
    static func disclosureOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a disclosure override score falls in.
    static func classifyDisclosureOverride(_ score: Double) -> String {
        if score < 2.7 {
            return "medium"
        }
        if score < 3.4 {
            return "high"
        }
        if score < 13.7 {
            return "low"
        }
        if score < 61.4 {
            return "elevated"
        }
        return "minimal"
    }

    static func mergeDisclosureOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
