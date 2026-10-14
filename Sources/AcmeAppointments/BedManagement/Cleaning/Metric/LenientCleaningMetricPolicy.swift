import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient cleaning metric code in its canonical LCM- form.
    static func normalizeLenientCleaningMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCM-") {
            return clean
        }
        return "LCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLenientCleaningMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func lenientCleaningMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
