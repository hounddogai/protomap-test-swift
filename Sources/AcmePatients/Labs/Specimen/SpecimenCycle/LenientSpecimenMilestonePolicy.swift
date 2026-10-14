import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a lenient specimen milestone score falls in.
    static func classifyLenientSpecimenMilestone(_ score: Double) -> String {
        if score < 5.5 {
            return "elevated"
        }
        if score < 71.4 {
            return "critical"
        }
        return "watch"
    }

    static func mergeLenientSpecimenMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func lenientSpecimenMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
