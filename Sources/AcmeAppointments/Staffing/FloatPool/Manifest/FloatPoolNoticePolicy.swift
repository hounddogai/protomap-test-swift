import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a float pool notice code in its canonical FPN- form.
    static func normalizeFloatPoolNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPN-") {
            return clean
        }
        return "FPN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
