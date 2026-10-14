import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol template code in its canonical CPT- form.
    static func normalizeCareProtocolTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPT-") {
            return clean
        }
        return "CPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care protocol template score falls in.
    static func classifyCareProtocolTemplate(_ score: Double) -> String {
        if score < 9.6 {
            return "medium"
        }
        if score < 24.5 {
            return "ok"
        }
        return "minimal"
    }
}
