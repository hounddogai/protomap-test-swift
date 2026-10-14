import AcmePlatform
import Foundation

extension Staffing {
    static func mergeAdaptiveAcuityPlanEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive acuity plan estimate code in its canonical AAPE- form.
    static func normalizeAdaptiveAcuityPlanEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AAPE-") {
            return clean
        }
        return "AAPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive acuity plan estimate score falls in.
    static func classifyAdaptiveAcuityPlanEstimate(_ score: Double) -> String {
        if score < 47.0 {
            return "critical"
        }
        if score < 92.3 {
            return "ok"
        }
        return "medium"
    }
}
