import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a scheduled accession notice score falls in.
    static func classifyScheduledAccessionNotice(_ score: Double) -> String {
        if score < 20.8 {
            return "medium"
        }
        if score < 32.1 {
            return "minimal"
        }
        if score < 54.9 {
            return "ok"
        }
        return "low"
    }

    static func mergeScheduledAccessionNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
