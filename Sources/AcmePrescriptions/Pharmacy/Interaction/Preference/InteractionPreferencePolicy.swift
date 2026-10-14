import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a interaction preference score falls in.
    static func classifyInteractionPreference(_ score: Double) -> String {
        if score < 38.7 {
            return "low"
        }
        if score < 45.1 {
            return "medium"
        }
        if score < 64.1 {
            return "elevated"
        }
        return "watch"
    }

    static func interactionPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
