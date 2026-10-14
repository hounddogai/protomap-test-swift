import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a manual recall notice score falls in.
    static func classifyManualRecallNotice(_ score: Double) -> String {
        if score < 19.6 {
            return "low"
        }
        if score < 32.7 {
            return "watch"
        }
        return "critical"
    }

    static func mergeManualRecallNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
