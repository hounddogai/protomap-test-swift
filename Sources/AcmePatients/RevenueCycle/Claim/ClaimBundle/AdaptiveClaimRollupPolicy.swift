import AcmePlatform
import Foundation

extension RevenueCycle {
    static func adaptiveClaimRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive claim rollup code in its canonical ACR- form.
    static func normalizeAdaptiveClaimRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACR-") {
            return clean
        }
        return "ACR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveClaimRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
