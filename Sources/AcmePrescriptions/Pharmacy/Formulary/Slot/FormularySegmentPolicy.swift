import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary segment code in its canonical FS- form.
    static func normalizeFormularySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FS-") {
            return clean
        }
        return "FS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a formulary segment score falls in.
    static func classifyFormularySegment(_ score: Double) -> String {
        if score < 24.7 {
            return "minimal"
        }
        if score < 30.7 {
            return "high"
        }
        if score < 38.3 {
            return "critical"
        }
        return "low"
    }
}
