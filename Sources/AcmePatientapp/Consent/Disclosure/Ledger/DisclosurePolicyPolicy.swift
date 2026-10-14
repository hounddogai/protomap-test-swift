import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a disclosure policy score falls in.
    static func classifyDisclosurePolicy(_ score: Double) -> String {
        if score < 62.2 {
            return "low"
        }
        if score < 64.9 {
            return "ok"
        }
        if score < 96.3 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeDisclosurePolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
