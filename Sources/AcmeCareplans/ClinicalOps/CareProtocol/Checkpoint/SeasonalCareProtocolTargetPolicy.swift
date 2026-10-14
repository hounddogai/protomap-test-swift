import AcmePlatform
import Foundation

extension ClinicalOps {
    static func seasonalCareProtocolTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal care protocol target score falls in.
    static func classifySeasonalCareProtocolTarget(_ score: Double) -> String {
        if score < 2.3 {
            return "minimal"
        }
        if score < 82.7 {
            return "elevated"
        }
        return "critical"
    }

    static func seasonalCareProtocolTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func seasonalCareProtocolTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
