import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func assessmentBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a assessment baseline score falls in.
    static func classifyAssessmentBaseline(_ score: Double) -> String {
        if score < 33.2 {
            return "medium"
        }
        if score < 35.8 {
            return "low"
        }
        if score < 54.0 {
            return "watch"
        }
        return "ok"
    }
}
