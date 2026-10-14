import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a capped statement digest score falls in.
    static func classifyCappedStatementDigest(_ score: Double) -> String {
        if score < 45.4 {
            return "medium"
        }
        if score < 58.5 {
            return "high"
        }
        return "minimal"
    }

    static func cappedStatementDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cappedStatementDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
