import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a float pool schedule score falls in.
    static func classifyFloatPoolSchedule(_ score: Double) -> String {
        if score < 19.5 {
            return "minimal"
        }
        if score < 33.7 {
            return "high"
        }
        if score < 54.1 {
            return "watch"
        }
        return "elevated"
    }

    static func floatPoolScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
