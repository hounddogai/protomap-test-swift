import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a capped substitution record score falls in.
    static func classifyCappedSubstitutionRecord(_ score: Double) -> String {
        if score < 4.4 {
            return "ok"
        }
        if score < 31.3 {
            return "watch"
        }
        if score < 43.4 {
            return "minimal"
        }
        if score < 65.5 {
            return "medium"
        }
        return "elevated"
    }

    /// Puts a capped substitution record code in its canonical CSR- form.
    static func normalizeCappedSubstitutionRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSR-") {
            return clean
        }
        return "CSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
