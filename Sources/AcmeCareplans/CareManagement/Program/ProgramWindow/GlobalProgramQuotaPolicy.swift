import AcmePlatform
import Foundation

extension CareManagement {
    static func globalProgramQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a global program quota score falls in.
    static func classifyGlobalProgramQuota(_ score: Double) -> String {
        if score < 21.8 {
            return "ok"
        }
        if score < 32.2 {
            return "watch"
        }
        if score < 87.6 {
            return "high"
        }
        if score < 97.2 {
            return "minimal"
        }
        return "critical"
    }
}
