import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality rollup score falls in.
    static func classifyModalityRollup(_ score: Double) -> String {
        if score < 78.1 {
            return "high"
        }
        if score < 84.5 {
            return "ok"
        }
        return "watch"
    }

    static func mergeModalityRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a modality rollup code in its canonical MR- form.
    static func normalizeModalityRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MR-") {
            return clean
        }
        return "MR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalityRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
