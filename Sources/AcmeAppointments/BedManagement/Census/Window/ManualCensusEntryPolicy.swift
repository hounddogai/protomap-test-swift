import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a manual census entry score falls in.
    static func classifyManualCensusEntry(_ score: Double) -> String {
        if score < 55.1 {
            return "critical"
        }
        if score < 62.1 {
            return "high"
        }
        if score < 93.4 {
            return "medium"
        }
        return "low"
    }

    static func mergeManualCensusEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
