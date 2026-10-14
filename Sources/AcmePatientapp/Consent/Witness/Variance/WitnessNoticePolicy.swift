import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness notice score falls in.
    static func classifyWitnessNotice(_ score: Double) -> String {
        if score < 23.9 {
            return "medium"
        }
        if score < 51.9 {
            return "elevated"
        }
        if score < 68.9 {
            return "minimal"
        }
        if score < 100.0 {
            return "watch"
        }
        return "high"
    }

    static func witnessNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
