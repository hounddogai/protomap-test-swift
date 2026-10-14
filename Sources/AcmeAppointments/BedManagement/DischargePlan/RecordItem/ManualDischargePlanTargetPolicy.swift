import AcmePlatform
import Foundation

extension BedManagement {
    static func manualDischargePlanTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual discharge plan target score falls in.
    static func classifyManualDischargePlanTarget(_ score: Double) -> String {
        if score < 17.5 {
            return "high"
        }
        if score < 35.6 {
            return "minimal"
        }
        if score < 53.5 {
            return "elevated"
        }
        return "low"
    }

    static func manualDischargePlanTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
