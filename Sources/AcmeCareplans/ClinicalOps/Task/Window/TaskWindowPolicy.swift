import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task window score falls in.
    static func classifyTaskWindow(_ score: Double) -> String {
        if score < 5.8 {
            return "minimal"
        }
        if score < 67.7 {
            return "high"
        }
        if score < 75.8 {
            return "low"
        }
        if score < 77.5 {
            return "critical"
        }
        return "medium"
    }

    static func taskWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
