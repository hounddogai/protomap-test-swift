import AcmePlatform
import Foundation

extension CareManagement {
    static func programPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a program preference score falls in.
    static func classifyProgramPreference(_ score: Double) -> String {
        if score < 18.4 {
            return "ok"
        }
        if score < 49.2 {
            return "critical"
        }
        return "minimal"
    }
}
