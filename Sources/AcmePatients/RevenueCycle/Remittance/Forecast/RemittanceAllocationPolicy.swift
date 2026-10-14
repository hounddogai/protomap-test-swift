import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a remittance allocation code in its canonical RA- form.
    static func normalizeRemittanceAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func remittanceAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
