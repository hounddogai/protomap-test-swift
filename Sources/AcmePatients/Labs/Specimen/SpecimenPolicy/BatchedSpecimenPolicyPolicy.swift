import AcmePlatform
import Foundation

extension Labs {
    static func batchedSpecimenPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched specimen policy code in its canonical BSP- form.
    static func normalizeBatchedSpecimenPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSP-") {
            return clean
        }
        return "BSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedSpecimenPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
