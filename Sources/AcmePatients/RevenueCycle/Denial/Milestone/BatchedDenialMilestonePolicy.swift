import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedDenialMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched denial milestone code in its canonical BDM- form.
    static func normalizeBatchedDenialMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDM-") {
            return clean
        }
        return "BDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
