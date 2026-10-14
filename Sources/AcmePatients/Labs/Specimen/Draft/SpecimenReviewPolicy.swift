import AcmePlatform
import Foundation

extension Labs {
    static func specimenReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a specimen review score falls in.
    static func classifySpecimenReview(_ score: Double) -> String {
        if score < 47.6 {
            return "high"
        }
        if score < 57.2 {
            return "minimal"
        }
        return "low"
    }
}
