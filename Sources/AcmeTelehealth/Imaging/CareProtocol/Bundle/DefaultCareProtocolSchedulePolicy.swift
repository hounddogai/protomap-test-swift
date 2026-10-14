import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a default care protocol schedule score falls in.
    static func classifyDefaultCareProtocolSchedule(_ score: Double) -> String {
        if score < 12.1 {
            return "watch"
        }
        if score < 27.7 {
            return "ok"
        }
        if score < 81.2 {
            return "elevated"
        }
        return "high"
    }

    static func defaultCareProtocolScheduleSpan(_ start: Int, end: Int) -> Int {
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
