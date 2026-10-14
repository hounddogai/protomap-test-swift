import AcmePlatform
import Foundation

extension Referrals {
    static func rollingClosureProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling closure profile score falls in.
    static func classifyRollingClosureProfile(_ score: Double) -> String {
        if score < 17.6 {
            return "critical"
        }
        if score < 34.5 {
            return "low"
        }
        return "watch"
    }
}
