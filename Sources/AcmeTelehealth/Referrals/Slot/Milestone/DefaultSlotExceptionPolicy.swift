import AcmePlatform
import Foundation

extension Referrals {
    static func defaultSlotExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a default slot exception score falls in.
    static func classifyDefaultSlotException(_ score: Double) -> String {
        if score < 82.4 {
            return "watch"
        }
        if score < 85.1 {
            return "critical"
        }
        if score < 92.3 {
            return "ok"
        }
        return "elevated"
    }
}
