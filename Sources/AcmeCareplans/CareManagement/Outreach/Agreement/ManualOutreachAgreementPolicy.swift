import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual outreach agreement score falls in.
    static func classifyManualOutreachAgreement(_ score: Double) -> String {
        if score < 3.2 {
            return "high"
        }
        if score < 73.8 {
            return "watch"
        }
        return "elevated"
    }

    static func manualOutreachAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
