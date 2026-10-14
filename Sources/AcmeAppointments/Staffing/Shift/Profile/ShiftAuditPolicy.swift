import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a shift audit score falls in.
    static func classifyShiftAudit(_ score: Double) -> String {
        if score < 17.1 {
            return "low"
        }
        if score < 50.9 {
            return "watch"
        }
        if score < 86.7 {
            return "ok"
        }
        return "medium"
    }

    static func mergeShiftAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
