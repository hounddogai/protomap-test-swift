import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a assessment entry score falls in.
    static func classifyAssessmentEntry(_ score: Double) -> String {
        if score < 8.1 {
            return "watch"
        }
        if score < 15.4 {
            return "ok"
        }
        if score < 17.2 {
            return "medium"
        }
        if score < 46.9 {
            return "critical"
        }
        return "low"
    }
}
