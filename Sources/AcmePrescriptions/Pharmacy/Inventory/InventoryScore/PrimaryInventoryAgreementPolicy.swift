import AcmePlatform
import Foundation

extension Pharmacy {
    static func primaryInventoryAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergePrimaryInventoryAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary inventory agreement code in its canonical PIA- form.
    static func normalizePrimaryInventoryAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIA-") {
            return clean
        }
        return "PIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
