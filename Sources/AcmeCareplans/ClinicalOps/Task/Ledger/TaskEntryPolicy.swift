import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a task entry code in its canonical TE- form.
    static func normalizeTaskEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TE-") {
            return clean
        }
        return "TE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a task entry score falls in.
    static func classifyTaskEntry(_ score: Double) -> String {
        if score < 44.3 {
            return "watch"
        }
        if score < 51.9 {
            return "medium"
        }
        if score < 90.2 {
            return "elevated"
        }
        return "ok"
    }
}
