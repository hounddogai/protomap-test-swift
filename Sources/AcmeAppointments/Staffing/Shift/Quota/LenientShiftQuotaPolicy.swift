import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a lenient shift quota score falls in.
    static func classifyLenientShiftQuota(_ score: Double) -> String {
        if score < 10.2 {
            return "medium"
        }
        if score < 48.6 {
            return "high"
        }
        if score < 50.8 {
            return "minimal"
        }
        if score < 99.1 {
            return "ok"
        }
        return "watch"
    }

    static func lenientShiftQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func lenientShiftQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
