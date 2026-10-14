import AcmePlatform
import Foundation

extension Imaging {
    static func mergeCareProtocolPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a care protocol preference code in its canonical CPP- form.
    static func normalizeCareProtocolPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPP-") {
            return clean
        }
        return "CPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
