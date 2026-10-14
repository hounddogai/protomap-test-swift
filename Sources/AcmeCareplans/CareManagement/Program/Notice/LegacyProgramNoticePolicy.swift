import AcmePlatform
import Foundation

extension CareManagement {
    static func legacyProgramNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a legacy program notice score falls in.
    static func classifyLegacyProgramNotice(_ score: Double) -> String {
        if score < 1.3 {
            return "ok"
        }
        if score < 26.1 {
            return "minimal"
        }
        return "watch"
    }

    static func legacyProgramNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
