import AcmePlatform
import Foundation

extension Labs {
    static func mergeScheduledAccessionPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledAccessionPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a scheduled accession preference code in its canonical SAP- form.
    static func normalizeScheduledAccessionPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAP-") {
            return clean
        }
        return "SAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
