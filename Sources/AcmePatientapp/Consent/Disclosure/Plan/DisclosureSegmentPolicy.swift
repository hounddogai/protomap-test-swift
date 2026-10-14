import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure segment code in its canonical DS- form.
    static func normalizeDisclosureSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DS-") {
            return clean
        }
        return "DS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func disclosureSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func disclosureSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
