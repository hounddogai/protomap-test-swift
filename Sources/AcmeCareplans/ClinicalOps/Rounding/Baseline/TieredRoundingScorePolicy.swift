import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredRoundingScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a tiered rounding score score falls in.
    static func classifyTieredRoundingScore(_ score: Double) -> String {
        if score < 4.9 {
            return "ok"
        }
        if score < 22.8 {
            return "elevated"
        }
        if score < 41.3 {
            return "watch"
        }
        if score < 67.1 {
            return "high"
        }
        return "minimal"
    }
}
