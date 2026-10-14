import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol entry code in its canonical CPE- form.
    static func normalizeCareProtocolEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPE-") {
            return clean
        }
        return "CPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
