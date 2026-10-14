import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeBedBoardMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a bed board metric score falls in.
    static func classifyBedBoardMetric(_ score: Double) -> String {
        if score < 9.0 {
            return "elevated"
        }
        if score < 44.5 {
            return "low"
        }
        return "high"
    }

    static func bedBoardMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
