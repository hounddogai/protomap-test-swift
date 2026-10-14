import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a shift mapping score falls in.
    static func classifyShiftMapping(_ score: Double) -> String {
        if score < 6.8 {
            return "high"
        }
        if score < 76.7 {
            return "medium"
        }
        if score < 82.1 {
            return "critical"
        }
        return "minimal"
    }

    /// Puts a shift mapping code in its canonical SM- form.
    static func normalizeShiftMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SM-") {
            return clean
        }
        return "SM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeShiftMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
