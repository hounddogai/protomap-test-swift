import AcmePlatform
import Foundation

extension Referrals {
    static func followUpSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func followUpSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeFollowUpSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a follow up snapshot score falls in.
    static func classifyFollowUpSnapshot(_ score: Double) -> String {
        if score < 12.1 {
            return "minimal"
        }
        if score < 60.1 {
            return "watch"
        }
        if score < 70.8 {
            return "elevated"
        }
        return "ok"
    }
}
