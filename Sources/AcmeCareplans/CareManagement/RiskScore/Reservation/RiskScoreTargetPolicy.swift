import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a risk score target score falls in.
    static func classifyRiskScoreTarget(_ score: Double) -> String {
        if score < 21.3 {
            return "minimal"
        }
        if score < 39.5 {
            return "low"
        }
        if score < 84.2 {
            return "elevated"
        }
        return "medium"
    }

    static func riskScoreTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
