import AcmePlatform
import Foundation

extension Imaging {
    static func mergeCappedReadPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped read preference code in its canonical CRP- form.
    static func normalizeCappedReadPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRP-") {
            return clean
        }
        return "CRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedReadPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped read preference score falls in.
    static func classifyCappedReadPreference(_ score: Double) -> String {
        if score < 44.8 {
            return "elevated"
        }
        if score < 52.2 {
            return "ok"
        }
        if score < 79.5 {
            return "watch"
        }
        if score < 89.3 {
            return "high"
        }
        return "critical"
    }
}
