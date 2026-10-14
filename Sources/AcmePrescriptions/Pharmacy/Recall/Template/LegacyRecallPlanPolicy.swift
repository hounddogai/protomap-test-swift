import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a legacy recall plan score falls in.
    static func classifyLegacyRecallPlan(_ score: Double) -> String {
        if score < 41.0 {
            return "critical"
        }
        if score < 65.3 {
            return "high"
        }
        if score < 89.9 {
            return "medium"
        }
        return "ok"
    }

    static func mergeLegacyRecallPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy recall plan code in its canonical LRP- form.
    static func normalizeLegacyRecallPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRP-") {
            return clean
        }
        return "LRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
