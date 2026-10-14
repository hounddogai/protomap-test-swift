import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a bed board threshold code in its canonical BBT- form.
    static func normalizeBedBoardThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBT-") {
            return clean
        }
        return "BBT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func bedBoardThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
