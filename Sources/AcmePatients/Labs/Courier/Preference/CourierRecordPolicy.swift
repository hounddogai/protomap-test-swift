import AcmePlatform
import Foundation

extension Labs {
    /// Puts a courier record code in its canonical CR- form.
    static func normalizeCourierRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a courier record score falls in.
    static func classifyCourierRecord(_ score: Double) -> String {
        if score < 66.5 {
            return "low"
        }
        if score < 86.7 {
            return "critical"
        }
        return "high"
    }
}
