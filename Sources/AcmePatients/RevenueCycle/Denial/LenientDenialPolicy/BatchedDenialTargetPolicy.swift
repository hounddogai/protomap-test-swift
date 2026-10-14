import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a batched denial target code in its canonical BDT- form.
    static func normalizeBatchedDenialTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDT-") {
            return clean
        }
        return "BDT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedDenialTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
