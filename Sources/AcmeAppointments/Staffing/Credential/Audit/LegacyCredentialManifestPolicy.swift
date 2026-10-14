import AcmePlatform
import Foundation

extension Staffing {
    static func legacyCredentialManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a legacy credential manifest score falls in.
    static func classifyLegacyCredentialManifest(_ score: Double) -> String {
        if score < 6.5 {
            return "medium"
        }
        if score < 31.6 {
            return "low"
        }
        if score < 58.9 {
            return "ok"
        }
        if score < 72.0 {
            return "critical"
        }
        return "minimal"
    }
}
