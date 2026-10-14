import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a seasonal remittance group code in its canonical SRG- form.
    static func normalizeSeasonalRemittanceGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRG-") {
            return clean
        }
        return "SRG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalRemittanceGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
