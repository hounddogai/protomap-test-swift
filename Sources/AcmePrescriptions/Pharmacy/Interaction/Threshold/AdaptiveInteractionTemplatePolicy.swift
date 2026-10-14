import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a adaptive interaction template score falls in.
    static func classifyAdaptiveInteractionTemplate(_ score: Double) -> String {
        if score < 27.0 {
            return "low"
        }
        if score < 38.8 {
            return "high"
        }
        if score < 58.3 {
            return "critical"
        }
        if score < 99.3 {
            return "ok"
        }
        return "minimal"
    }

    static func mergeAdaptiveInteractionTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveInteractionTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
