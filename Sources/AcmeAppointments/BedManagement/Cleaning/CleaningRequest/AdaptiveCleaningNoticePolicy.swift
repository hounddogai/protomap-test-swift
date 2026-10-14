import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveCleaningNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a adaptive cleaning notice code in its canonical ACN- form.
    static func normalizeAdaptiveCleaningNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACN-") {
            return clean
        }
        return "ACN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
