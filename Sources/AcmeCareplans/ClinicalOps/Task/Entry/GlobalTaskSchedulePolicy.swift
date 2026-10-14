import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a global task schedule score falls in.
    static func classifyGlobalTaskSchedule(_ score: Double) -> String {
        if score < 4.9 {
            return "watch"
        }
        if score < 9.7 {
            return "critical"
        }
        if score < 69.4 {
            return "elevated"
        }
        return "ok"
    }

    static func globalTaskScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
