import AcmePlatform
import Foundation

extension Staffing {
    static func adaptiveShiftNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func adaptiveShiftNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive shift notice score falls in.
    static func classifyAdaptiveShiftNotice(_ score: Double) -> String {
        if score < 78.8 {
            return "ok"
        }
        if score < 86.1 {
            return "high"
        }
        if score < 93.9 {
            return "critical"
        }
        return "medium"
    }
}
