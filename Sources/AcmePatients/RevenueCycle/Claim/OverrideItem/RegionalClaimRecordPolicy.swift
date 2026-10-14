import AcmePlatform
import Foundation

extension RevenueCycle {
    static func regionalClaimRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a regional claim record score falls in.
    static func classifyRegionalClaimRecord(_ score: Double) -> String {
        if score < 12.9 {
            return "minimal"
        }
        if score < 58.1 {
            return "watch"
        }
        if score < 76.6 {
            return "low"
        }
        if score < 77.4 {
            return "critical"
        }
        return "ok"
    }
}
