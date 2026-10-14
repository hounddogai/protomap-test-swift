import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeGlobalSubstitutionScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalSubstitutionScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a global substitution score score falls in.
    static func classifyGlobalSubstitutionScore(_ score: Double) -> String {
        if score < 6.6 {
            return "medium"
        }
        if score < 64.8 {
            return "low"
        }
        return "watch"
    }
}
