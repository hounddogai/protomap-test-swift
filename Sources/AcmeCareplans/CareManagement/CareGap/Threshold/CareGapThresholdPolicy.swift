import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap threshold score falls in.
    static func classifyCareGapThreshold(_ score: Double) -> String {
        if score < 28.2 {
            return "elevated"
        }
        if score < 33.3 {
            return "medium"
        }
        if score < 49.7 {
            return "watch"
        }
        return "ok"
    }

    /// Puts a care gap threshold code in its canonical CGT- form.
    static func normalizeCareGapThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGT-") {
            return clean
        }
        return "CGT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
