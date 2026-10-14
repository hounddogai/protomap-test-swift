import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a risk score baseline score falls in.
    static func classifyRiskScoreBaseline(_ score: Double) -> String {
        if score < 38.4 {
            return "elevated"
        }
        if score < 89.8 {
            return "low"
        }
        return "minimal"
    }
}
