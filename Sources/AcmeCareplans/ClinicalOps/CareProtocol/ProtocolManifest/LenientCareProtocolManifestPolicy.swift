import AcmePlatform
import Foundation

extension ClinicalOps {
    static func lenientCareProtocolManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a lenient care protocol manifest score falls in.
    static func classifyLenientCareProtocolManifest(_ score: Double) -> String {
        if score < 19.8 {
            return "elevated"
        }
        if score < 89.3 {
            return "medium"
        }
        if score < 97.1 {
            return "critical"
        }
        return "high"
    }
}
