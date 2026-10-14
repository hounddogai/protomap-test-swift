import AcmePlatform
import Foundation

extension Consent {
    static func disclosureForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a disclosure forecast code in its canonical DF- form.
    static func normalizeDisclosureForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DF-") {
            return clean
        }
        return "DF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
