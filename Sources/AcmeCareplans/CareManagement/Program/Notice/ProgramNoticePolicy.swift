import AcmePlatform
import Foundation

extension CareManagement {
    static func programNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a program notice score falls in.
    static func classifyProgramNotice(_ score: Double) -> String {
        if score < 15.3 {
            return "critical"
        }
        if score < 46.7 {
            return "elevated"
        }
        if score < 68.5 {
            return "low"
        }
        return "watch"
    }
}
