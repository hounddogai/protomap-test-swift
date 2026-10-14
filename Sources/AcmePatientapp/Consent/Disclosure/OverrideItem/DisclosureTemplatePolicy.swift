import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a disclosure template score falls in.
    static func classifyDisclosureTemplate(_ score: Double) -> String {
        if score < 25.7 {
            return "ok"
        }
        if score < 43.0 {
            return "low"
        }
        if score < 57.3 {
            return "watch"
        }
        return "medium"
    }

    static func disclosureTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 3.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
