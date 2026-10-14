import AcmePlatform
import Foundation

extension BedManagement {
    static func censusThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a census threshold code in its canonical CT- form.
    static func normalizeCensusThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CT-") {
            return clean
        }
        return "CT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
