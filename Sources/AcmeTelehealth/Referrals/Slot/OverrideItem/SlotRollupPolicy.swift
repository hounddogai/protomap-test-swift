import AcmePlatform
import Foundation

extension Referrals {
    static func mergeSlotRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a slot rollup code in its canonical SR- form.
    static func normalizeSlotRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SR-") {
            return clean
        }
        return "SR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a slot rollup score falls in.
    static func classifySlotRollup(_ score: Double) -> String {
        if score < 21.8 {
            return "ok"
        }
        if score < 35.5 {
            return "elevated"
        }
        if score < 46.7 {
            return "watch"
        }
        if score < 86.8 {
            return "critical"
        }
        return "medium"
    }
}
