import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a handoff mapping score falls in.
    static func classifyHandoffMapping(_ score: Double) -> String {
        if score < 28.4 {
            return "high"
        }
        if score < 29.1 {
            return "minimal"
        }
        if score < 80.3 {
            return "medium"
        }
        if score < 85.0 {
            return "watch"
        }
        return "ok"
    }

    /// Puts a handoff mapping code in its canonical HM- form.
    static func normalizeHandoffMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HM-") {
            return clean
        }
        return "HM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
