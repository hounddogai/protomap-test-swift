import AcmePlatform
import Foundation

extension ClinicalOps {
    static func scheduledCareProtocolProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a scheduled care protocol profile code in its canonical SCPP- form.
    static func normalizeScheduledCareProtocolProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPP-") {
            return clean
        }
        return "SCPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
