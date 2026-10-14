import AcmePlatform
import Foundation

extension Consent {
    static func mergeLegacyDisclosureClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy disclosure claim score falls in.
    static func classifyLegacyDisclosureClaim(_ score: Double) -> String {
        if score < 43.3 {
            return "critical"
        }
        if score < 58.7 {
            return "elevated"
        }
        return "low"
    }
}
