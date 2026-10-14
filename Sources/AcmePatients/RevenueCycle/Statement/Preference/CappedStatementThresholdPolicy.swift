import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedStatementThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a capped statement threshold score falls in.
    static func classifyCappedStatementThreshold(_ score: Double) -> String {
        if score < 7.0 {
            return "elevated"
        }
        if score < 14.9 {
            return "critical"
        }
        return "watch"
    }
}
