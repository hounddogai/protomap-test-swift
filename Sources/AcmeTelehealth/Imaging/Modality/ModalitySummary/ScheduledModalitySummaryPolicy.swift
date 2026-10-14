import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a scheduled modality summary score falls in.
    static func classifyScheduledModalitySummary(_ score: Double) -> String {
        if score < 5.7 {
            return "high"
        }
        if score < 14.2 {
            return "ok"
        }
        if score < 50.1 {
            return "watch"
        }
        if score < 55.0 {
            return "low"
        }
        return "medium"
    }

    static func scheduledModalitySummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
