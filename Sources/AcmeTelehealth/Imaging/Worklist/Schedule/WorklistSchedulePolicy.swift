import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist schedule score falls in.
    static func classifyWorklistSchedule(_ score: Double) -> String {
        if score < 4.0 {
            return "low"
        }
        if score < 14.3 {
            return "medium"
        }
        if score < 28.4 {
            return "high"
        }
        if score < 41.6 {
            return "ok"
        }
        return "watch"
    }

    static func worklistScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
