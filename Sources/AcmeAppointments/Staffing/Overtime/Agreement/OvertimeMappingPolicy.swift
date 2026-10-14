import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime mapping code in its canonical OM- form.
    static func normalizeOvertimeMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OM-") {
            return clean
        }
        return "OM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeOvertimeMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func overtimeMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
