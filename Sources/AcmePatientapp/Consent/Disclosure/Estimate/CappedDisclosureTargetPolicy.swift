import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a capped disclosure target score falls in.
    static func classifyCappedDisclosureTarget(_ score: Double) -> String {
        if score < 47.9 {
            return "ok"
        }
        if score < 60.2 {
            return "watch"
        }
        return "elevated"
    }

    static func cappedDisclosureTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
