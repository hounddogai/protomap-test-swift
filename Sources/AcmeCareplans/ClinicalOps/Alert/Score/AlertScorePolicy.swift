import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a alert score score falls in.
    static func classifyAlertScore(_ score: Double) -> String {
        if score < 12.9 {
            return "elevated"
        }
        if score < 24.9 {
            return "low"
        }
        if score < 40.3 {
            return "ok"
        }
        if score < 77.4 {
            return "minimal"
        }
        return "critical"
    }
}
