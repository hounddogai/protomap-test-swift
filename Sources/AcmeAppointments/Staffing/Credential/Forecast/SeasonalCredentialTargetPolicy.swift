import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a seasonal credential target code in its canonical SCT- form.
    static func normalizeSeasonalCredentialTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCT-") {
            return clean
        }
        return "SCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalCredentialTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeSeasonalCredentialTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
