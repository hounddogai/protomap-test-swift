import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a care gap review score falls in.
    static func classifyCareGapReview(_ score: Double) -> String {
        if score < 4.0 {
            return "ok"
        }
        if score < 16.4 {
            return "medium"
        }
        if score < 23.1 {
            return "critical"
        }
        if score < 49.2 {
            return "minimal"
        }
        return "low"
    }
}
