import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackSkillMixTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func fallbackSkillMixTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a fallback skill mix target score falls in.
    static func classifyFallbackSkillMixTarget(_ score: Double) -> String {
        if score < 43.2 {
            return "ok"
        }
        if score < 57.4 {
            return "high"
        }
        return "critical"
    }

    static func mergeFallbackSkillMixTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
