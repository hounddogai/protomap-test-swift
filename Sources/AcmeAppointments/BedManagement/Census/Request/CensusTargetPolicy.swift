import AcmePlatform
import Foundation

extension BedManagement {
    static func censusTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a census target code in its canonical CT- form.
    static func normalizeCensusTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CT-") {
            return clean
        }
        return "CT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func censusTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
