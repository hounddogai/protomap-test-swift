import AcmePlatform
import Foundation

extension ClinicalOps {
    static func legacyAlertSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a legacy alert slot code in its canonical LAS- form.
    static func normalizeLegacyAlertSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAS-") {
            return clean
        }
        return "LAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyAlertSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
