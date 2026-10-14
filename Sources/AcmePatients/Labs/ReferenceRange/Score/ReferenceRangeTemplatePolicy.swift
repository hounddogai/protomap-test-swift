import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a reference range template score falls in.
    static func classifyReferenceRangeTemplate(_ score: Double) -> String {
        if score < 18.5 {
            return "medium"
        }
        if score < 94.6 {
            return "low"
        }
        if score < 94.6 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a reference range template code in its canonical RRT- form.
    static func normalizeReferenceRangeTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRT-") {
            return clean
        }
        return "RRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
