import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a regional alert metric code in its canonical RAM- form.
    static func normalizeRegionalAlertMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAM-") {
            return clean
        }
        return "RAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalAlertMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
