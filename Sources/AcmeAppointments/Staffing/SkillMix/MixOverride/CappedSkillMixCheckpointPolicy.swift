import AcmePlatform
import Foundation

extension Staffing {
    static func mergeCappedSkillMixCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedSkillMixCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cappedSkillMixCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a capped skill mix checkpoint score falls in.
    static func classifyCappedSkillMixCheckpoint(_ score: Double) -> String {
        if score < 8.7 {
            return "critical"
        }
        if score < 27.8 {
            return "high"
        }
        if score < 42.0 {
            return "ok"
        }
        if score < 77.7 {
            return "low"
        }
        return "minimal"
    }
}
