import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a legacy order set reservation code in its canonical LOSR- form.
    static func normalizeLegacyOrderSetReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOSR-") {
            return clean
        }
        return "LOSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyOrderSetReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
