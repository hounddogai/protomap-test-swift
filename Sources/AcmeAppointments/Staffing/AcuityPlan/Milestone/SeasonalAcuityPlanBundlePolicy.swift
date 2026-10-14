import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a seasonal acuity plan bundle score falls in.
    static func classifySeasonalAcuityPlanBundle(_ score: Double) -> String {
        if score < 53.4 {
            return "high"
        }
        if score < 97.7 {
            return "medium"
        }
        return "watch"
    }

    static func seasonalAcuityPlanBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
