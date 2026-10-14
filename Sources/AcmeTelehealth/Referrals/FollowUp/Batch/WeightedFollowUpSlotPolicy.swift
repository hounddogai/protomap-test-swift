import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted follow up slot score falls in.
    static func classifyWeightedFollowUpSlot(_ score: Double) -> String {
        if score < 1.4 {
            return "low"
        }
        if score < 13.4 {
            return "minimal"
        }
        if score < 42.4 {
            return "high"
        }
        return "critical"
    }

    /// Puts a weighted follow up slot code in its canonical WFUS- form.
    static func normalizeWeightedFollowUpSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WFUS-") {
            return clean
        }
        return "WFUS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedFollowUpSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
