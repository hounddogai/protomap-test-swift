import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a capped inventory preference score falls in.
    static func classifyCappedInventoryPreference(_ score: Double) -> String {
        if score < 15.9 {
            return "ok"
        }
        if score < 72.9 {
            return "low"
        }
        return "elevated"
    }

    static func cappedInventoryPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a capped inventory preference code in its canonical CIP- form.
    static func normalizeCappedInventoryPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CIP-") {
            return clean
        }
        return "CIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
