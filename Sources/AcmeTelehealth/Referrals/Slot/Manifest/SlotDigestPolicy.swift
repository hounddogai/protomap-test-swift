import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot digest code in its canonical SD- form.
    static func normalizeSlotDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SD-") {
            return clean
        }
        return "SD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a slot digest score falls in.
    static func classifySlotDigest(_ score: Double) -> String {
        if score < 18.1 {
            return "critical"
        }
        if score < 65.5 {
            return "low"
        }
        if score < 66.4 {
            return "ok"
        }
        if score < 72.5 {
            return "watch"
        }
        return "minimal"
    }

    static func mergeSlotDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
