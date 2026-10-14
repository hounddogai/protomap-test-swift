import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePrimaryOutreachReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary outreach review score falls in.
    static func classifyPrimaryOutreachReview(_ score: Double) -> String {
        if score < 52.2 {
            return "ok"
        }
        if score < 76.8 {
            return "medium"
        }
        return "high"
    }
}
