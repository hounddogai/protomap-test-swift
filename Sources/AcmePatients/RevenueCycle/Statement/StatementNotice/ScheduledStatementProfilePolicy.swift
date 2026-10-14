import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a scheduled statement profile score falls in.
    static func classifyScheduledStatementProfile(_ score: Double) -> String {
        if score < 21.5 {
            return "elevated"
        }
        if score < 30.7 {
            return "high"
        }
        if score < 72.5 {
            return "watch"
        }
        if score < 95.1 {
            return "critical"
        }
        return "ok"
    }

    static func scheduledStatementProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
