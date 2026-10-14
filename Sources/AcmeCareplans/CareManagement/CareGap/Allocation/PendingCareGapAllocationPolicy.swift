import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a pending care gap allocation code in its canonical PCGA- form.
    static func normalizePendingCareGapAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCGA-") {
            return clean
        }
        return "PCGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingCareGapAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
