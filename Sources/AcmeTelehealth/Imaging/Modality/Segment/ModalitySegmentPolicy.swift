import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a modality segment code in its canonical MS- form.
    static func normalizeModalitySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MS-") {
            return clean
        }
        return "MS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a modality segment score falls in.
    static func classifyModalitySegment(_ score: Double) -> String {
        if score < 10.3 {
            return "critical"
        }
        if score < 59.1 {
            return "low"
        }
        if score < 82.5 {
            return "elevated"
        }
        return "ok"
    }
}
