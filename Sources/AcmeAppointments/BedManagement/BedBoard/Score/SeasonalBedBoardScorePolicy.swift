import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeSeasonalBedBoardScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a seasonal bed board score score falls in.
    static func classifySeasonalBedBoardScore(_ score: Double) -> String {
        if score < 12.2 {
            return "medium"
        }
        if score < 67.1 {
            return "watch"
        }
        return "elevated"
    }
}
