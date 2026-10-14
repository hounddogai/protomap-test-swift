import AcmePlatform
import Foundation

extension Labs {
    static func legacyReferenceRangeProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a legacy reference range profile code in its canonical LRRP- form.
    static func normalizeLegacyReferenceRangeProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRP-") {
            return clean
        }
        return "LRRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyReferenceRangeProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy reference range profile score falls in.
    static func classifyLegacyReferenceRangeProfile(_ score: Double) -> String {
        if score < 17.2 {
            return "ok"
        }
        if score < 32.1 {
            return "elevated"
        }
        if score < 87.7 {
            return "watch"
        }
        return "critical"
    }
}
