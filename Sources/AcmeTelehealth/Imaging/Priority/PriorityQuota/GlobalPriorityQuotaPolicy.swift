import AcmePlatform
import Foundation

extension Imaging {
    static func globalPriorityQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a global priority quota score falls in.
    static func classifyGlobalPriorityQuota(_ score: Double) -> String {
        if score < 28.0 {
            return "medium"
        }
        if score < 95.2 {
            return "elevated"
        }
        return "watch"
    }
}
