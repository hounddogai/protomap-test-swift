import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a legacy statement threshold code in its canonical LST- form.
    static func normalizeLegacyStatementThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LST-") {
            return clean
        }
        return "LST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyStatementThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
