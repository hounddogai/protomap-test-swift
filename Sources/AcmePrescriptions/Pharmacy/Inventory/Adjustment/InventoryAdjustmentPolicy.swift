import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInventoryAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a inventory adjustment code in its canonical IA- form.
    static func normalizeInventoryAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IA-") {
            return clean
        }
        return "IA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a inventory adjustment score falls in.
    static func classifyInventoryAdjustment(_ score: Double) -> String {
        if score < 8.9 {
            return "critical"
        }
        if score < 70.1 {
            return "high"
        }
        return "minimal"
    }

    static func inventoryAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
