import AcmePlatform
import Foundation

extension Pharmacy {
    static func scheduledRecallAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a scheduled recall audit code in its canonical SRA- form.
    static func normalizeScheduledRecallAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRA-") {
            return clean
        }
        return "SRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
