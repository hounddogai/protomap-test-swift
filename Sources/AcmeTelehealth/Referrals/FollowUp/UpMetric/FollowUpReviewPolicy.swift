import AcmePlatform
import Foundation

extension Referrals {
    static func mergeFollowUpReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a follow up review score falls in.
    static func classifyFollowUpReview(_ score: Double) -> String {
        if score < 14.5 {
            return "ok"
        }
        if score < 37.0 {
            return "medium"
        }
        if score < 68.0 {
            return "elevated"
        }
        return "watch"
    }

    static func followUpReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
