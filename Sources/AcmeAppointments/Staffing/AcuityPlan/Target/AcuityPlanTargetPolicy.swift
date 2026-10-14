import AcmePlatform
import Foundation

extension Staffing {
    static func mergeAcuityPlanTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func acuityPlanTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a acuity plan target score falls in.
    static func classifyAcuityPlanTarget(_ score: Double) -> String {
        if score < 84.4 {
            return "low"
        }
        if score < 95.1 {
            return "critical"
        }
        return "elevated"
    }
}
