import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality estimate score falls in.
    static func classifyModalityEstimate(_ score: Double) -> String {
        if score < 34.6 {
            return "low"
        }
        if score < 45.8 {
            return "elevated"
        }
        return "minimal"
    }

    static func mergeModalityEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a modality estimate code in its canonical ME- form.
    static func normalizeModalityEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ME-") {
            return clean
        }
        return "ME-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
