import AcmePlatform
import Foundation

extension ClinicalOps {
    static func primaryHandoffCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a primary handoff cycle score falls in.
    static func classifyPrimaryHandoffCycle(_ score: Double) -> String {
        if score < 19.7 {
            return "low"
        }
        if score < 41.4 {
            return "high"
        }
        if score < 45.9 {
            return "watch"
        }
        return "minimal"
    }
}
