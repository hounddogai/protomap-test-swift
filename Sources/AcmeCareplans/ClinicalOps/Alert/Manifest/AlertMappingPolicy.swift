import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a alert mapping code in its canonical AM- form.
    static func normalizeAlertMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AM-") {
            return clean
        }
        return "AM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func alertMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func alertMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
