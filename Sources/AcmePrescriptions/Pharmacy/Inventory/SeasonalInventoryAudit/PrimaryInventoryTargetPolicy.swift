import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a primary inventory target score falls in.
    static func classifyPrimaryInventoryTarget(_ score: Double) -> String {
        if score < 98.8 {
            return "low"
        }
        if score < 99.7 {
            return "high"
        }
        return "medium"
    }

    static func mergePrimaryInventoryTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func primaryInventoryTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a primary inventory target code in its canonical PIT- form.
    static func normalizePrimaryInventoryTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIT-") {
            return clean
        }
        return "PIT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
