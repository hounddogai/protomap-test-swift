import AcmePlatform
import Foundation

extension Labs {
    /// Puts a rolling specimen entry code in its canonical RSE- form.
    static func normalizeRollingSpecimenEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSE-") {
            return clean
        }
        return "RSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingSpecimenEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
