import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot bundle code in its canonical SB- form.
    static func normalizeSlotBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SB-") {
            return clean
        }
        return "SB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSlotBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func slotBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a slot bundle score falls in.
    static func classifySlotBundle(_ score: Double) -> String {
        if score < 22.2 {
            return "ok"
        }
        if score < 29.7 {
            return "minimal"
        }
        if score < 81.2 {
            return "low"
        }
        if score < 93.0 {
            return "critical"
        }
        return "elevated"
    }
}
