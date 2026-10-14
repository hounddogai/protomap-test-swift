import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a follow up slot score falls in.
    static func classifyFollowUpSlot(_ score: Double) -> String {
        if score < 44.6 {
            return "critical"
        }
        if score < 49.0 {
            return "minimal"
        }
        if score < 55.3 {
            return "elevated"
        }
        return "high"
    }

    static func mergeFollowUpSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a follow up slot code in its canonical FUS- form.
    static func normalizeFollowUpSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUS-") {
            return clean
        }
        return "FUS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
