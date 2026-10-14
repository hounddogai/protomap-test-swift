import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a regional isolation policy code in its canonical RIP- form.
    static func normalizeRegionalIsolationPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RIP-") {
            return clean
        }
        return "RIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalIsolationPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
