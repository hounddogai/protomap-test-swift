import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a study group score falls in.
    static func classifyStudyGroup(_ score: Double) -> String {
        if score < 15.0 {
            return "medium"
        }
        if score < 35.0 {
            return "ok"
        }
        if score < 60.7 {
            return "elevated"
        }
        return "high"
    }

    static func studyGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
