import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a scheduled network bundle score falls in.
    static func classifyScheduledNetworkBundle(_ score: Double) -> String {
        if score < 3.4 {
            return "minimal"
        }
        if score < 29.4 {
            return "elevated"
        }
        return "watch"
    }

    static func scheduledNetworkBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
