import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a priority variance score falls in.
    static func classifyPriorityVariance(_ score: Double) -> String {
        if score < 39.9 {
            return "elevated"
        }
        if score < 41.8 {
            return "minimal"
        }
        if score < 64.5 {
            return "watch"
        }
        return "ok"
    }

    static func priorityVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
