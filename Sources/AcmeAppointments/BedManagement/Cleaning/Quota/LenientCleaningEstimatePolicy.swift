import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient cleaning estimate code in its canonical LCE- form.
    static func normalizeLenientCleaningEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCE-") {
            return clean
        }
        return "LCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientCleaningEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
