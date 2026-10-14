import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a rolling inventory draft code in its canonical RID- form.
    static func normalizeRollingInventoryDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RID-") {
            return clean
        }
        return "RID-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingInventoryDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
