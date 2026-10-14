import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a overtime window score falls in.
    static func classifyOvertimeWindow(_ score: Double) -> String {
        if score < 29.2 {
            return "critical"
        }
        if score < 87.5 {
            return "minimal"
        }
        return "medium"
    }

    static func overtimeWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
