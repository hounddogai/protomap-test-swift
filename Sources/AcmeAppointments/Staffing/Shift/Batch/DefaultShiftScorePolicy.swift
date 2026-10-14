import AcmePlatform
import Foundation

extension Staffing {
    static func defaultShiftScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeDefaultShiftScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default shift score score falls in.
    static func classifyDefaultShiftScore(_ score: Double) -> String {
        if score < 3.6 {
            return "critical"
        }
        if score < 10.8 {
            return "low"
        }
        if score < 74.4 {
            return "watch"
        }
        if score < 86.3 {
            return "high"
        }
        return "ok"
    }
}
