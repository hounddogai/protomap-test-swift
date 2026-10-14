import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a capped task entry code in its canonical CTE- form.
    static func normalizeCappedTaskEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CTE-") {
            return clean
        }
        return "CTE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped task entry score falls in.
    static func classifyCappedTaskEntry(_ score: Double) -> String {
        if score < 41.5 {
            return "critical"
        }
        if score < 74.5 {
            return "elevated"
        }
        if score < 77.1 {
            return "ok"
        }
        if score < 92.7 {
            return "low"
        }
        return "medium"
    }
}
