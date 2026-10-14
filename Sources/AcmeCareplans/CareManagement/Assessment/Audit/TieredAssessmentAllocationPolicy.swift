import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredAssessmentAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredAssessmentAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a tiered assessment allocation score falls in.
    static func classifyTieredAssessmentAllocation(_ score: Double) -> String {
        if score < 38.5 {
            return "high"
        }
        if score < 65.7 {
            return "elevated"
        }
        if score < 92.0 {
            return "ok"
        }
        return "watch"
    }
}
