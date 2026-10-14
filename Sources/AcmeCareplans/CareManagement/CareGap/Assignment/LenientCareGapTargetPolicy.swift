import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a lenient care gap target code in its canonical LCGT- form.
    static func normalizeLenientCareGapTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCGT-") {
            return clean
        }
        return "LCGT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientCareGapTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
