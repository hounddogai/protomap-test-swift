import AcmePlatform
import Foundation

extension CareManagement {
    static func strictRiskScoreNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func strictRiskScoreNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a strict risk score notice score falls in.
    static func classifyStrictRiskScoreNotice(_ score: Double) -> String {
        if score < 49.8 {
            return "low"
        }
        if score < 66.5 {
            return "minimal"
        }
        if score < 79.7 {
            return "critical"
        }
        return "watch"
    }
}
