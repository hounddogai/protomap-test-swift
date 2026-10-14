import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeHandoffGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func handoffGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func handoffGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a handoff group score falls in.
    static func classifyHandoffGroup(_ score: Double) -> String {
        if score < 33.9 {
            return "critical"
        }
        if score < 74.8 {
            return "high"
        }
        if score < 77.9 {
            return "low"
        }
        if score < 95.8 {
            return "minimal"
        }
        return "elevated"
    }
}
