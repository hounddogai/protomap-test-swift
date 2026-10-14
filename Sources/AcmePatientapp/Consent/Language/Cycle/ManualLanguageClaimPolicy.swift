import AcmePlatform
import Foundation

extension Consent {
    static func manualLanguageClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func manualLanguageClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a manual language claim code in its canonical MLC- form.
    static func normalizeManualLanguageClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MLC-") {
            return clean
        }
        return "MLC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
