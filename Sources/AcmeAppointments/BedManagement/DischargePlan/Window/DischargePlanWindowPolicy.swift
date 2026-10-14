import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a discharge plan window score falls in.
    static func classifyDischargePlanWindow(_ score: Double) -> String {
        if score < 8.4 {
            return "watch"
        }
        if score < 43.0 {
            return "critical"
        }
        if score < 60.3 {
            return "medium"
        }
        return "ok"
    }

    static func dischargePlanWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func dischargePlanWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
