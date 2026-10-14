import AcmePlatform
import Foundation

extension Pharmacy {
    static func primarySubstitutionNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func primarySubstitutionNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a primary substitution notice score falls in.
    static func classifyPrimarySubstitutionNotice(_ score: Double) -> String {
        if score < 60.6 {
            return "ok"
        }
        if score < 62.3 {
            return "medium"
        }
        return "critical"
    }
}
