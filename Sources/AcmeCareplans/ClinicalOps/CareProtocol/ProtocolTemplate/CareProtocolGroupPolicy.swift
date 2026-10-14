import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol group score falls in.
    static func classifyCareProtocolGroup(_ score: Double) -> String {
        if score < 54.0 {
            return "minimal"
        }
        if score < 56.8 {
            return "ok"
        }
        return "low"
    }

    /// Puts a care protocol group code in its canonical CPG- form.
    static func normalizeCareProtocolGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPG-") {
            return clean
        }
        return "CPG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
