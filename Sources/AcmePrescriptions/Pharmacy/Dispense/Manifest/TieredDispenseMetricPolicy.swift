import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeTieredDispenseMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredDispenseMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a tiered dispense metric code in its canonical TDM- form.
    static func normalizeTieredDispenseMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TDM-") {
            return clean
        }
        return "TDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
