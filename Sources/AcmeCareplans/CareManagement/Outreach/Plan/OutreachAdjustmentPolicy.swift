import AcmePlatform
import Foundation

extension CareManagement {
    static func outreachAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a outreach adjustment code in its canonical OA- form.
    static func normalizeOutreachAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OA-") {
            return clean
        }
        return "OA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
