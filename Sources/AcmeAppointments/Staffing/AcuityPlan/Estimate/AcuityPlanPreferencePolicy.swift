import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan preference score falls in.
    static func classifyAcuityPlanPreference(_ score: Double) -> String {
        if score < 24.3 {
            return "elevated"
        }
        if score < 73.2 {
            return "minimal"
        }
        if score < 89.5 {
            return "low"
        }
        return "medium"
    }

    static func acuityPlanPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
