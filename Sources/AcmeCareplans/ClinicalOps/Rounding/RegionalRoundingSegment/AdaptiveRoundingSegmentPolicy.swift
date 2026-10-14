import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a adaptive rounding segment score falls in.
    static func classifyAdaptiveRoundingSegment(_ score: Double) -> String {
        if score < 9.7 {
            return "elevated"
        }
        if score < 48.6 {
            return "critical"
        }
        if score < 65.7 {
            return "ok"
        }
        return "minimal"
    }

    static func adaptiveRoundingSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
