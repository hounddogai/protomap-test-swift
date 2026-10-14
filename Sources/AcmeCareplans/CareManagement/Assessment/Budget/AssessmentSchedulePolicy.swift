import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a assessment schedule score falls in.
    static func classifyAssessmentSchedule(_ score: Double) -> String {
        if score < 2.6 {
            return "watch"
        }
        if score < 72.2 {
            return "ok"
        }
        return "high"
    }
}
