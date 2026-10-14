import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDispenseMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a dispense mapping code in its canonical DM- form.
    static func normalizeDispenseMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DM-") {
            return clean
        }
        return "DM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dispenseMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a dispense mapping score falls in.
    static func classifyDispenseMapping(_ score: Double) -> String {
        if score < 14.0 {
            return "critical"
        }
        if score < 19.4 {
            return "low"
        }
        return "medium"
    }
}
