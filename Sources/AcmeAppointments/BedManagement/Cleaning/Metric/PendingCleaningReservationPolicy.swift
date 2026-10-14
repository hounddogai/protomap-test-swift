import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a pending cleaning reservation code in its canonical PCR- form.
    static func normalizePendingCleaningReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCR-") {
            return clean
        }
        return "PCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a pending cleaning reservation score falls in.
    static func classifyPendingCleaningReservation(_ score: Double) -> String {
        if score < 28.5 {
            return "critical"
        }
        if score < 59.2 {
            return "elevated"
        }
        if score < 84.2 {
            return "high"
        }
        return "low"
    }
}
