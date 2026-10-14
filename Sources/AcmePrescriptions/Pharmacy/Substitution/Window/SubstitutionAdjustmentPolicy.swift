import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a substitution adjustment score falls in.
    static func classifySubstitutionAdjustment(_ score: Double) -> String {
        if score < 48.5 {
            return "high"
        }
        if score < 62.8 {
            return "minimal"
        }
        return "watch"
    }

    static func substitutionAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
