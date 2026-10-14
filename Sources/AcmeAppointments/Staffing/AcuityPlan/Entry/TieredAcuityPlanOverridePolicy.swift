import AcmePlatform
import Foundation

extension Staffing {
    static func tieredAcuityPlanOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a tiered acuity plan override score falls in.
    static func classifyTieredAcuityPlanOverride(_ score: Double) -> String {
        if score < 12.5 {
            return "low"
        }
        if score < 30.0 {
            return "high"
        }
        if score < 69.9 {
            return "watch"
        }
        return "elevated"
    }
}
