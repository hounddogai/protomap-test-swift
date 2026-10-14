import AcmePlatform
import Foundation

extension Staffing {
    static func adaptiveAcuityPlanCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func adaptiveAcuityPlanCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive acuity plan cycle score falls in.
    static func classifyAdaptiveAcuityPlanCycle(_ score: Double) -> String {
        if score < 69.1 {
            return "critical"
        }
        if score < 69.8 {
            return "elevated"
        }
        return "ok"
    }
}
