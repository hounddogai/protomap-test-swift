import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredAssessmentManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a tiered assessment manifest score falls in.
    static func classifyTieredAssessmentManifest(_ score: Double) -> String {
        if score < 23.7 {
            return "elevated"
        }
        if score < 46.8 {
            return "critical"
        }
        return "minimal"
    }
}
