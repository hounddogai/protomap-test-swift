import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol milestone code in its canonical CPM- form.
    static func normalizeCareProtocolMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPM-") {
            return clean
        }
        return "CPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care protocol milestone score falls in.
    static func classifyCareProtocolMilestone(_ score: Double) -> String {
        if score < 78.8 {
            return "watch"
        }
        if score < 93.5 {
            return "elevated"
        }
        if score < 94.0 {
            return "medium"
        }
        return "minimal"
    }

    static func mergeCareProtocolMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
