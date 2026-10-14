import AcmePlatform
import Foundation

extension Labs {
    /// Puts a global courier tier code in its canonical GCT- form.
    static func normalizeGlobalCourierTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCT-") {
            return clean
        }
        return "GCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalCourierTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeGlobalCourierTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global courier tier score falls in.
    static func classifyGlobalCourierTier(_ score: Double) -> String {
        if score < 55.7 {
            return "low"
        }
        if score < 56.8 {
            return "elevated"
        }
        if score < 77.9 {
            return "ok"
        }
        return "watch"
    }
}
