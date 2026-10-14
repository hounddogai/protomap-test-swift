import AcmePlatform
import Foundation

extension Referrals {
    static func networkQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a network quota code in its canonical NQ- form.
    static func normalizeNetworkQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NQ-") {
            return clean
        }
        return "NQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
