import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeRollingSubstitutionClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a rolling substitution claim score falls in.
    static func classifyRollingSubstitutionClaim(_ score: Double) -> String {
        if score < 59.7 {
            return "medium"
        }
        if score < 76.5 {
            return "low"
        }
        return "minimal"
    }

    static func rollingSubstitutionClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
