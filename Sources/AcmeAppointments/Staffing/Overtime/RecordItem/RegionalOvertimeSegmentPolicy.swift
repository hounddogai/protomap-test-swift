import AcmePlatform
import Foundation

extension Staffing {
    static func mergeRegionalOvertimeSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional overtime segment score falls in.
    static func classifyRegionalOvertimeSegment(_ score: Double) -> String {
        if score < 11.6 {
            return "critical"
        }
        if score < 98.5 {
            return "elevated"
        }
        return "medium"
    }
}
