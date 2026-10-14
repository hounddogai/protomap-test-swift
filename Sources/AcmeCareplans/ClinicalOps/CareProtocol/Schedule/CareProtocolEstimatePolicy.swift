import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol estimate score falls in.
    static func classifyCareProtocolEstimate(_ score: Double) -> String {
        if score < 42.1 {
            return "minimal"
        }
        if score < 90.5 {
            return "medium"
        }
        return "ok"
    }

    static func mergeCareProtocolEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
