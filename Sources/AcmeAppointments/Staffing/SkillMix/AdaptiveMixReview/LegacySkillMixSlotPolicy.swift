import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a legacy skill mix slot score falls in.
    static func classifyLegacySkillMixSlot(_ score: Double) -> String {
        if score < 6.0 {
            return "elevated"
        }
        if score < 83.2 {
            return "minimal"
        }
        return "medium"
    }

    static func mergeLegacySkillMixSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
