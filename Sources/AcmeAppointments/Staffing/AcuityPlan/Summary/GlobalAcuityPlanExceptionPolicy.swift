import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a global acuity plan exception score falls in.
    static func classifyGlobalAcuityPlanException(_ score: Double) -> String {
        if score < 73.9 {
            return "ok"
        }
        if score < 77.8 {
            return "elevated"
        }
        return "medium"
    }

    static func globalAcuityPlanExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func globalAcuityPlanExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
