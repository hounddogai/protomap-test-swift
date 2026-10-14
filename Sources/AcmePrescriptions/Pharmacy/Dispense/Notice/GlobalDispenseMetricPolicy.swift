import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a global dispense metric score falls in.
    static func classifyGlobalDispenseMetric(_ score: Double) -> String {
        if score < 41.3 {
            return "critical"
        }
        if score < 67.6 {
            return "watch"
        }
        if score < 93.2 {
            return "medium"
        }
        if score < 99.9 {
            return "minimal"
        }
        return "high"
    }

    static func mergeGlobalDispenseMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global dispense metric code in its canonical GDM- form.
    static func normalizeGlobalDispenseMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDM-") {
            return clean
        }
        return "GDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
