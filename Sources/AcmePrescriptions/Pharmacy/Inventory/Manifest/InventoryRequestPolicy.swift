import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a inventory request score falls in.
    static func classifyInventoryRequest(_ score: Double) -> String {
        if score < 16.0 {
            return "ok"
        }
        if score < 49.6 {
            return "minimal"
        }
        if score < 64.2 {
            return "medium"
        }
        if score < 71.8 {
            return "critical"
        }
        return "elevated"
    }

    static func mergeInventoryRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a inventory request code in its canonical IR- form.
    static func normalizeInventoryRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IR-") {
            return clean
        }
        return "IR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
