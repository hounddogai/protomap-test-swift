import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a follow up assignment score falls in.
    static func classifyFollowUpAssignment(_ score: Double) -> String {
        if score < 21.9 {
            return "minimal"
        }
        if score < 31.2 {
            return "high"
        }
        if score < 53.1 {
            return "critical"
        }
        if score < 89.9 {
            return "ok"
        }
        return "elevated"
    }

    static func followUpAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func mergeFollowUpAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
