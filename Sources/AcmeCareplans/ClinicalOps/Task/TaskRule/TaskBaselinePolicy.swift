import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task baseline score falls in.
    static func classifyTaskBaseline(_ score: Double) -> String {
        if score < 61.9 {
            return "ok"
        }
        if score < 93.6 {
            return "high"
        }
        return "minimal"
    }

    /// Puts a task baseline code in its canonical TB- form.
    static func normalizeTaskBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TB-") {
            return clean
        }
        return "TB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeTaskBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
