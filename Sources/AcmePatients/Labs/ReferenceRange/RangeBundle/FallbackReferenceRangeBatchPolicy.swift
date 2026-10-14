import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a fallback reference range batch score falls in.
    static func classifyFallbackReferenceRangeBatch(_ score: Double) -> String {
        if score < 61.5 {
            return "ok"
        }
        if score < 68.9 {
            return "watch"
        }
        return "critical"
    }

    /// Puts a fallback reference range batch code in its canonical FRRB- form.
    static func normalizeFallbackReferenceRangeBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRRB-") {
            return clean
        }
        return "FRRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
