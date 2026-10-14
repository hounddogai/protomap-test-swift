import AcmePlatform
import Foundation

extension Labs {
    /// Puts a capped specimen quota code in its canonical CSQ- form.
    static func normalizeCappedSpecimenQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSQ-") {
            return clean
        }
        return "CSQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedSpecimenQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
