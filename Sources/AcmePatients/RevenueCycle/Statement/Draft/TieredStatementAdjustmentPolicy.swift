import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredStatementAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a tiered statement adjustment code in its canonical TSA- form.
    static func normalizeTieredStatementAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TSA-") {
            return clean
        }
        return "TSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
