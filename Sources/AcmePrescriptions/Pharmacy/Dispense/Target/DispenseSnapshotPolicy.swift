import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense snapshot score falls in.
    static func classifyDispenseSnapshot(_ score: Double) -> String {
        if score < 29.3 {
            return "medium"
        }
        if score < 54.4 {
            return "low"
        }
        return "elevated"
    }

    static func dispenseSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a dispense snapshot code in its canonical DS- form.
    static func normalizeDispenseSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DS-") {
            return clean
        }
        return "DS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDispenseSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
