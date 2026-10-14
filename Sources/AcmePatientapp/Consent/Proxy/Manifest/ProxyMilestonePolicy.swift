import AcmePlatform
import Foundation

extension Consent {
    /// Puts a proxy milestone code in its canonical PM- form.
    static func normalizeProxyMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PM-") {
            return clean
        }
        return "PM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a proxy milestone score falls in.
    static func classifyProxyMilestone(_ score: Double) -> String {
        if score < 51.2 {
            return "high"
        }
        if score < 83.8 {
            return "minimal"
        }
        if score < 96.3 {
            return "critical"
        }
        return "medium"
    }

    static func mergeProxyMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
