import AcmePlatform
import Foundation

extension Imaging {
    static func modalityOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a modality override score falls in.
    static func classifyModalityOverride(_ score: Double) -> String {
        if score < 47.4 {
            return "watch"
        }
        if score < 88.5 {
            return "high"
        }
        return "minimal"
    }

    static func mergeModalityOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a modality override code in its canonical MO- form.
    static func normalizeModalityOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MO-") {
            return clean
        }
        return "MO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
