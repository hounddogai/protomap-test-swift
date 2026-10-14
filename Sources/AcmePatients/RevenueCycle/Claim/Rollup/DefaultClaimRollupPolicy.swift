import AcmePlatform
import Foundation

extension RevenueCycle {
    static func defaultClaimRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a default claim rollup code in its canonical DCR- form.
    static func normalizeDefaultClaimRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCR-") {
            return clean
        }
        return "DCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
