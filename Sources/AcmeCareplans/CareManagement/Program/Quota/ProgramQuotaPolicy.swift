import AcmePlatform
import Foundation

extension CareManagement {
    static func programQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a program quota score falls in.
    static func classifyProgramQuota(_ score: Double) -> String {
        if score < 55.1 {
            return "elevated"
        }
        if score < 68.5 {
            return "minimal"
        }
        return "medium"
    }
}
