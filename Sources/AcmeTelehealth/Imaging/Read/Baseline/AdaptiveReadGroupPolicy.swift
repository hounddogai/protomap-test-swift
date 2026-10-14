import AcmePlatform
import Foundation

extension Imaging {
    static func mergeAdaptiveReadGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive read group code in its canonical ARG- form.
    static func normalizeAdaptiveReadGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARG-") {
            return clean
        }
        return "ARG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveReadGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
