import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInventoryDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func inventoryDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a inventory draft code in its canonical ID- form.
    static func normalizeInventoryDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ID-") {
            return clean
        }
        return "ID-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a inventory draft score falls in.
    static func classifyInventoryDraft(_ score: Double) -> String {
        if score < 32.9 {
            return "critical"
        }
        if score < 80.8 {
            return "low"
        }
        if score < 91.1 {
            return "watch"
        }
        return "ok"
    }
}
