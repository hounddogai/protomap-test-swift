import AcmePlatform
import Foundation

extension Labs {
    static func regionalPanelDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a regional panel digest score falls in.
    static func classifyRegionalPanelDigest(_ score: Double) -> String {
        if score < 13.9 {
            return "medium"
        }
        if score < 51.4 {
            return "elevated"
        }
        return "high"
    }
}
