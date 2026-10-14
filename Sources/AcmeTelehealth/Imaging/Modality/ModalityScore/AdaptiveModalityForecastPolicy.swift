import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a adaptive modality forecast code in its canonical AMF- form.
    static func normalizeAdaptiveModalityForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AMF-") {
            return clean
        }
        return "AMF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveModalityForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeAdaptiveModalityForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
