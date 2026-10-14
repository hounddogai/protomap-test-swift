import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score milestone score falls in.
    static func classifyRiskScoreMilestone(_ score: Double) -> String {
        if score < 37.5 {
            return "elevated"
        }
        if score < 69.8 {
            return "medium"
        }
        if score < 86.1 {
            return "low"
        }
        if score < 86.3 {
            return "ok"
        }
        return "watch"
    }

    static func riskScoreMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
