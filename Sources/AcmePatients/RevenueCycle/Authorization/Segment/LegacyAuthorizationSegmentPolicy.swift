import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a legacy authorization segment score falls in.
    static func classifyLegacyAuthorizationSegment(_ score: Double) -> String {
        if score < 26.3 {
            return "elevated"
        }
        if score < 80.0 {
            return "minimal"
        }
        return "critical"
    }

    static func mergeLegacyAuthorizationSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
