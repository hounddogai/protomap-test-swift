import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalAssessmentNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional assessment notice score falls in.
    static func classifyRegionalAssessmentNotice(_ score: Double) -> String {
        if score < 4.5 {
            return "elevated"
        }
        if score < 80.7 {
            return "critical"
        }
        if score < 94.8 {
            return "high"
        }
        return "minimal"
    }
}
