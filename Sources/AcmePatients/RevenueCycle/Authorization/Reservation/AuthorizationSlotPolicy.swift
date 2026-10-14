import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization slot score falls in.
    static func classifyAuthorizationSlot(_ score: Double) -> String {
        if score < 26.9 {
            return "elevated"
        }
        if score < 80.4 {
            return "low"
        }
        if score < 82.5 {
            return "high"
        }
        return "critical"
    }

    static func mergeAuthorizationSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
