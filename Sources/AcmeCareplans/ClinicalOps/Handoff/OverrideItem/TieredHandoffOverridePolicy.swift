import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredHandoffOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a tiered handoff override score falls in.
    static func classifyTieredHandoffOverride(_ score: Double) -> String {
        if score < 34.2 {
            return "medium"
        }
        if score < 58.1 {
            return "low"
        }
        if score < 92.9 {
            return "high"
        }
        return "watch"
    }
}
