import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a risk score schedule score falls in.
    static func classifyRiskScoreSchedule(_ score: Double) -> String {
        if score < 19.2 {
            return "watch"
        }
        if score < 40.7 {
            return "low"
        }
        return "ok"
    }
}
