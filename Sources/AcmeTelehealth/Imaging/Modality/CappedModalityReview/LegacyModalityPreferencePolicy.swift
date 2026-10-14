import AcmePlatform
import Foundation

extension Imaging {
    static func legacyModalityPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a legacy modality preference score falls in.
    static func classifyLegacyModalityPreference(_ score: Double) -> String {
        if score < 1.8 {
            return "watch"
        }
        if score < 58.9 {
            return "low"
        }
        if score < 74.7 {
            return "high"
        }
        if score < 83.9 {
            return "elevated"
        }
        return "minimal"
    }
}
