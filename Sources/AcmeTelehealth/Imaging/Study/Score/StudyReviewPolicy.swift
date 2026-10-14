import AcmePlatform
import Foundation

extension Imaging {
    static func studyReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a study review score falls in.
    static func classifyStudyReview(_ score: Double) -> String {
        if score < 20.5 {
            return "low"
        }
        if score < 54.9 {
            return "elevated"
        }
        if score < 92.1 {
            return "critical"
        }
        return "medium"
    }
}
