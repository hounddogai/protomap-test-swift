import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending care gap target score falls in.
    static func classifyPendingCareGapTarget(_ score: Double) -> String {
        if score < 37.2 {
            return "medium"
        }
        if score < 85.2 {
            return "ok"
        }
        return "elevated"
    }

    static func pendingCareGapTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
