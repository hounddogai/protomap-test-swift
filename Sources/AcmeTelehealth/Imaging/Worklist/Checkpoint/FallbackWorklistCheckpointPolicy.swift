import AcmePlatform
import Foundation

extension Imaging {
    static func fallbackWorklistCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a fallback worklist checkpoint code in its canonical FWC- form.
    static func normalizeFallbackWorklistCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FWC-") {
            return clean
        }
        return "FWC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFallbackWorklistCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
