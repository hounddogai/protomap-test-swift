import AcmePlatform
import Foundation

extension Imaging {
    static func studyTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a study tier score falls in.
    static func classifyStudyTier(_ score: Double) -> String {
        if score < 10.8 {
            return "high"
        }
        if score < 68.7 {
            return "watch"
        }
        if score < 73.9 {
            return "minimal"
        }
        return "elevated"
    }
}
