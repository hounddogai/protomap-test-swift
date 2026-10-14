import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a study notice score falls in.
    static func classifyStudyNotice(_ score: Double) -> String {
        if score < 36.6 {
            return "low"
        }
        if score < 67.6 {
            return "critical"
        }
        if score < 76.7 {
            return "medium"
        }
        if score < 93.0 {
            return "watch"
        }
        return "high"
    }

    static func studyNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func studyNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
