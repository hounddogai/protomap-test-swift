import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeCensusPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a census preference score falls in.
    static func classifyCensusPreference(_ score: Double) -> String {
        if score < 6.8 {
            return "minimal"
        }
        if score < 18.9 {
            return "low"
        }
        if score < 30.1 {
            return "high"
        }
        if score < 77.4 {
            return "elevated"
        }
        return "ok"
    }

    static func censusPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a census preference code in its canonical CP- form.
    static func normalizeCensusPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
